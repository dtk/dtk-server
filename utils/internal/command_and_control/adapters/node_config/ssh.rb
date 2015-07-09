module DTK
  module CommandAndControlAdapter
    class Ssh < CommandAndControlNodeConfig
      def self.initiate_execution(task_idh, top_task_idh, task_action, opts)
        SSHDriverTest1.test_start(task_idh, top_task_idh, task_action, opts)
      end

      def self.initiate_cancelation(task_idh, top_task_idh, task_action, opts)
        SSHDriverTest1.test_cancel(task_idh, top_task_idh, task_action, opts)
      end
    end
  end
end

require 'em-ssh'
require 'mcollective'
module DTK
  class SSHDriverTest1
    def self.test_start(_task_idh, _top_task_idh, task_action, opts)
      @connections = []
      install_script_file_path = nil
      upload_error = false

      if node = task_action[:node]
        external_ref = node[:external_ref]
        ssh_credentials = external_ref[:ssh_credentials]

        host =  external_ref[:routable_host_address]
        user = ssh_credentials[:ssh_user]
        password = ssh_credentials[:ssh_password]

        unless callbacks = (opts[:receiver_context] || {})[:callbacks]
          raise Error.new('Unexpected that no calls given')
        end

        install_script = CommandAndControl.install_script(node)

        EM::Ssh.start(host, user, password: password) do |connection|
          conn_host = connection.host
          home_path = R8.app_user_home()

          connection.errback do |err|
            connection.close
            if err.is_a?(EventMachine::Ssh::NegotiationTimeout)
              msg = { msg: 'NegotiationTimeout' }
              callbacks[:on_cancel].call(msg)
            elsif err.is_a?(Net::SSH::AuthenticationFailed)
              msg = { msg: 'AuthenticationFailed' }
              callbacks[:on_timeout].call(msg)
            else
              msg = { msg: 'ConnectionTimeout' }
              callbacks[:on_timeout].call(msg)
            end
          end

          connection.callback do |ssh|
            # adding connections to @connections to be able to close them when cancel command is called
            @connections << { connection: connection, ssh: ssh }

            ssh.exec!('rm -rf /tmp/dtk-node-agent') do |_channel, stream, data|
              STDOUT << "#{conn_host}: #{data}" if stream == :stdout
            end

            begin
              install_script_file = Tempfile.new('install_script')
              install_script_file.write(install_script)
              install_script_file.close
              install_script_file_path = install_script_file.path

              # executing upload commands
              ssh.scp.upload!(install_script_file_path, '/tmp', recursive: true)
              ssh.scp.upload!("#{home_path}/dtk-node-agent", '/tmp', recursive: true)
            rescue Exception => e
              puts "\n[ERROR] Error occured in SCP.upload to host '#{conn_host}': #{e}.\n"
              puts '[ERROR] Rest of the commands will not be executed on this host!'
              upload_error = true
            ensure
              install_script_file.unlink
            end

            if upload_error
              msg = { ssh: ssh, em: EM }
              callbacks[:on_cancel].call(msg)
            else
              install_command = user.eql?('root') ? 'bash /tmp/dtk-node-agent/install_agent.sh' : 'sudo bash /tmp/dtk-node-agent/install_agent.sh'
              ssh.exec!(install_command) do |_channel, stream, data|
                STDOUT << "#{conn_host}: #{data}" if stream == :stdout
              end

              ssh.exec!('rm -rf /tmp/dtk-node-agent') do |_channel, stream, data|
                STDOUT << "#{conn_host}: #{data}" if stream == :stdout
              end

              install_script_command = user.eql?('root') ? "bash #{install_script_file_path}" : "sudo bash #{install_script_file_path}"
              ssh.exec!(install_script_command) do |_channel, stream, data|
                STDOUT << "#{conn_host}: #{data}" if stream == :stdout
              end

              ssh.exec!("rm -rf #{install_script_file_path}") do |_channel, stream, data|
                STDOUT << "#{conn_host}: #{data}" if stream == :stdout
              end

              puts "'#{conn_host}' COMPLETED SUCCESSFULLY!"
              msg = { msg: "'#{conn_host}' COMPLETED SUCCESSFULLY!" }
              callbacks[:on_msg_received].call(msg)
            end
          end
        end
      end
    end

    def self.test_cancel(_task_idh, _top_task_idh, _task_action, opts)
      puts '===================== SSH CANCEL CALLED ===================='
      callbacks = (opts[:receiver_context] || {})[:callbacks]
      # should not use EM.stop for cancel, need to find better solution
      # EM.stop
      @connections.each do |conn|
        # need Fiber.new to avoid message 'can't yield from root fiber'
        Fiber.new do
          conn[:ssh].close
          conn[:connection].close
        end.resume
      end

      msg = { msg: 'CANCEL' }
      callbacks[:on_msg_received].call(msg)
    end
  end
end
