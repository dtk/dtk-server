module DTK
  module CommandAndControlAdapter
    class Ssh < CommandAndControlNodeConfig
      def self.initiate_execution(task_idh,top_task_idh,task_action,opts)
        raise Error.new('ssh processing of actions needs to be written')
      end
    end
  end
end

