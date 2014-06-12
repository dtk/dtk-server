module DTK
  module CommandAndControlAdapter
    class Ssh < CommandAndControlNodeConfig
      def self.initiate_execution(task_idh,top_task_idh,task_action,opts)
        SSHDriverTest1.test_start(task_idh,top_task_idh,task_action,opts)
      end
    end
  end
end

require 'em-ssh'
module DTK
  class SSHDriverTest1
    def self.test_start(task_idh,top_task_idh,task_action,opts)
      #TODO: stub that gets values from yaml file/tmp/node_config_ssh.yaml
      # host: ec2-54-196-7-64.compute-1.amazonaws.com
      # user: rich
      # password: foo
      # delay: 20
      input =  YAML.load(File.open('/tmp/node_config_ssh.yaml'))
      host =  input['host']
      user = input['user']
      password = input['password']
      delay = input[:delay]||10
      unless callbacks = (opts[:receiver_context]||{})[:callbacks]
        raise Error.new("Unexpected that no calls given")
      end
      #TODO: jsut stubbed response with success need to do same for error and timeout
      EM::Ssh.start(host, user, :password => password) do |connection|
        connection.errback do |err|
          $stderr.puts "#{err} (#{err.class})"
          EM.stop
        end
        connection.callback do |ssh|
          ssh.exec!("sleep #{delay} && ls") do |channel, stream, data|
            STDOUT << "data_from_ssh\n#{data}"
            msg = {:msg => data}
            callbacks[:on_msg_received].call(msg) 
          end
        end
      end
    end
  end
end
