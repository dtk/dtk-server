require 'thread'
require 'timeout'
require 'net/ssh'
require 'net/scp'
require 'mcollective'

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
      servers, install_script, mcollective_client = [], nil, nil

      #TODO: better to use tempfile library; see how it is used in ../server/utils/internal/command_and_control/adapters/node_config/mcollective/config.rb
      install_script_file_path = "#{R8.app_user_home()}/install_script"
      FileUtils.mkdir(install_script_file_path) unless File.directory?(install_script_file_path)

      # create mcollective-client instance
      # not using our custom mcollective client because discover is not working properly with it
      mcollective_client = ::MCollective::Client.new('/etc/mcollective/client.cfg')
      mcollective_client.options = {}

      # here we set information we need to connect to nodes via ssh
      unmanaged_nodes.each do |node|
        node.update_object!(:ref)

        install_script = CommandAndControl.install_script(node)
        install_script_file_name = "install_script_#{node[:id]}"

        servers << {
          "dtk_node_agent_location" => "#{R8.app_user_home()}/dtk-node-agent",
          "install_script_file_path" => install_script_file_path,
          "install_script_file_name" => install_script_file_name,
          "node" => node,
          "mcollective_client" => mcollective_client
        }

        File.open("#{install_script_file_path}/#{install_script_file_name}", 'w') do |f|
          f.puts(install_script)
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
        FileUtils.rm_rf(install_script_file_path)
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
        Log.info_pp(['SshJob#call',:message,message[:node]])
        node = message["node"]
        mcollective_client = message["mcollective_client"]
        external_ref = node.get_external_ref()

        unless hostname = external_ref[:routable_host_address]
          raise ErrorUsage.new("#{name_and_id(node)} is missing routable_host_address")
        end
        unless ssh_credentials = external_ref[:ssh_credentials]
          raise ErrorUsage.new("#{name_and_id(node)} is missing ssh_credentials")
        end
        [:ssh_user,:ssh_password].each do |ssh_attr|
          unless ssh_credentials[ssh_attr]
            raise ErrorUsage.new("#{name_and_id(node)} is missing ssh_credentials field #{ssh_attr}")
          end
        end

        params = {
          :hostname => external_ref[:routable_host_address],
          :user => ssh_credentials[:ssh_user],
          :password => ssh_credentials[:ssh_password],
          :port => ssh_credentials[:port]||"22",
          :id => node.id()
        }


        #just to test taht can connect
        begin
          execute_ssh_command("ls /", params)
        rescue Exception => e
          Log.info_pp(['SshJob#call',:error,e, :params, params])
          return
        end
        
        execute_ssh_command("rm -rf /tmp/dtk-node-agent", params)

        Net::SCP.upload!(params[:hostname], params[:user],
          "#{message["install_script_file_path"]}/#{message["install_script_file_name"]}", "/tmp",
          :ssh => { :password => params[:password], :port => params[:port] }, :recursive => true)

        Net::SCP.upload!(params[:hostname], params[:user],
          message["dtk_node_agent_location"], "/tmp",
          :ssh => { :password => params[:password], :port => params[:port] }, :recursive => true)

        # perform installation
        install_command = params[:user].eql?('root') ? "bash /tmp/dtk-node-agent/install_agent.sh" : "sudo bash /tmp/dtk-node-agent/install_agent.sh"
        execute_ssh_command(install_command, params)
        execute_ssh_command("rm -rf /tmp/dtk-node-agent", params)

        install_script_command = params[:user].eql?('root') ? "bash /tmp/#{message['install_script_file_name']}" : "sudo bash /tmp/#{message['install_script_file_name']}"
        execute_ssh_command(install_script_command, params)
        execute_ssh_command("rm -rf /tmp/#{message['install_script_file_name']}", params)

        # sleep set to 2 seconds to be sure that mcollective on node is ready to listen for discovery
        sleep(2)

        # send discover call filtered by 'pbuilderid'(node[:ref] == pbuilderid)
        # if empty array is returned, agent on node is not working as expected
        filter = {"fact"=>[{:fact=>"pbuilderid",:value=>node[:ref],:operator=>"=="}], "cf_class"=>[], "agent"=>[], "identity"=>[], "compound"=>[]}
        discovered_data = CommandAndControl.discover(filter, 3, 1, mcollective_client)

        # set managed = true only if mcollective from node returns valid response
        if discovered_data.is_a?(Array)
          node.update(:managed => true) unless discovered_data.empty?
        else
          node.update(:managed => true) unless (discovered_data.nil? && discovered_data.payload.nil?)
        end
      end

     private
      def name_and_id(node)
        node.pp_name_and_id(:capitalize=>true)
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
