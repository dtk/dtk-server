require 'thread'
require 'timeout'
require 'net/ssh'
require 'net/scp'

module DTK; class Target
  class InstallAgentsHelper
    def initialize(target)
      @target = target
    end
    def self.install(target)
      new(target).install
    end
    def install()
      # we get all the nodes that are 'unmanaged', meaning they are physical nodes that does not have node agent installed
      unmanaged_nodes = @target.get_objs(:cols => [:unmanaged_nodes]).map{|r|r[:node]}
      servers, user_data = [], nil

      user_data_file_path = "#{R8.app_user_home()}/user_data"
      FileUtils.mkdir(user_data_file_path) unless File.directory?(user_data_file_path)
      # here we set information we need to connect to nodes via ssh
      unmanaged_nodes.each do |node|
        node.update_object!(:ref)

        user_data = CommandAndControl.install_script(node)
        user_data_file_name = "user_data_#{node[:id]}"

        servers << {
          "dtk_node_agent_location" => "#{R8.app_user_home()}/dtk-node-agent",
          "user_data_file_path" => user_data_file_path,
          "user_data_file_name" => user_data_file_name,
          "node" => node
        }

        File.open("#{user_data_file_path}/#{user_data_file_name}", 'w') do |f|
          f.puts(user_data)
        end
      end

      # add jobs to the queue
      servers.each do |server|
        Work.enqueue(SshJob, server)
      end

      # start the workers
      Work.start
      # wait for all jobs to finnish
      begin
        Work.drain
      rescue Timeout::Error => e
        # stop the workers
        Work.stop
      ensure
        FileUtils.rm_rf(user_data_file_path)
      end
    end

    # we use this module to handle multithreading, and if some node is not reachable or some error happens on the node
    # we just ignore it
    module Work
      @queue     = Queue.new
      @n_threads = R8::Config[:workflow][:install_agents][:threads].to_i||10
      @workers   = []
      @running   = true
      @servers_per_thread = 0

      Job = Struct.new(:worker, :params)

      module_function
      def enqueue(worker, *params)
          @queue << Job.new(worker, params)
      end

      def start
        @servers_per_thread = (@queue.size/@n_threads) + 1
        @n_threads.times do
          @workers << Thread.new do
            begin
              @servers_per_thread.times.map {process_jobs}
            ensure
              Thread.current.exit
            end
          end
        end
      end

      def process_jobs
        while !@queue.empty?
          job = nil
          job = @queue.pop
          job.worker.new.call(*job.params)
        end
      end

      def drain
        t_out = R8::Config[:workflow][:install_agents][:timeout].to_i||600
        Timeout.timeout(t_out) do
          loop do
            break unless @workers.any?{|w| w.alive?}
            sleep 1
          end
        end
      end

      def stop
        @running = false
        @workers.each do |t|
          t.exit() if t.status.eql?('sleep')
        end
      end
    end

    # this is the job that will upload node agent to physical nodes using Net::SCP.upload! command
    # and after that we execute some commands on the node itself using execute_ssh_command() method
    class SshJob
      def call(message)
        puts message
        node = message["node"]
        external_ref = node[:external_ref]

        params = {
          :hostname => external_ref[:routable_host_address],
          :user => external_ref[:ssh_credentials][:ssh_user],
          :password => external_ref[:ssh_credentials][:ssh_password],
          :port => external_ref[:ssh_credentials][:port]||"22",
          :id => node[:id]
        }

        begin
          execute_ssh_command("ls /", params)
        rescue Exception => e
          puts "#{e.message}. Params: #{params}"
          return
        end

        execute_ssh_command("rm -rf /tmp/dtk-node-agent", params)

        Net::SCP.upload!(params[:hostname], params[:user],
          "#{message["user_data_file_path"]}/#{message["user_data_file_name"]}", "/tmp",
          :ssh => { :password => params[:password], :port => params[:port] }, :recursive => true)

        Net::SCP.upload!(params[:hostname], params[:user],
          message["dtk_node_agent_location"], "/tmp",
          :ssh => { :password => params[:password], :port => params[:port] }, :recursive => true)

        # perform installation
        install_command = params[:user].eql?('root') ? "bash /tmp/dtk-node-agent/install_agent.sh" : "sudo bash /tmp/dtk-node-agent/install_agent.sh"
        execute_ssh_command(install_command, params)
        execute_ssh_command("rm -rf /tmp/dtk-node-agent", params)

        user_data_command = params[:user].eql?('root') ? "bash /tmp/#{message['user_data_file_name']}" : "sudo bash /tmp/#{message['user_data_file_name']}"
        execute_ssh_command(user_data_command, params)
        execute_ssh_command("rm -rf /tmp/#{message['user_data_file_name']}", params)

        node.update(:managed => true)
      end

      def execute_ssh_command(command, params={})
        Net::SSH.start(params[:hostname], params[:user], :password => params[:password], :port => params[:port]) do |ssh|
          # capture all stderr and stdout output from a remote process
          ssh.exec!(command) do |channel, stream, line|
            puts "#{params[:hostname]} > #{line}"
          end
        end
      end
    end
  end
end; end
