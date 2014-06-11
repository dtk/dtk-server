module DTK
  module CommandAndControlAdapter
    class Ssh < CommandAndControlNodeConfig
      def self.initiate_execution(task_idh,top_task_idh,task_action,opts)
        SSHDriverTest1.test_start(nil,nil,nil)
      end
    end
  end
end

require 'em-ssh'
module DTK
  class SSHDriverTest1
    def self.test_start(node,credential_hash,task_action)
      host_and_cred = stub_get_host_and_credentials()
      host =  host_and_cred['host']
      user = host_and_cred['user']
      password = host_and_cred['password']
      EM::Ssh.start(host, user, :password => password) do |connection|
        connection.errback do |err|
          $stderr.puts "#{err} (#{err.class})"
          EM.stop
        end
        connection.callback do |ssh|
          ssh.exec!("sleep 5 && ls") do |channel, stream, data|
            puts data #if stream == :stdout
          end
        end
      end
    end

    private
    def self.stub_get_host_and_credentials()
      YAML.load(File.open('/tmp/node_config_ssh.yaml'))
    end

  end
end
