module DTK
  module CommandAndControlAdapter
    class Smoketest < CommandAndControlNodeConfig
      def self.initiate_execution(task_idh, top_task_idh, task_action, opts)
        SSHDriverTest1.smoketest_start(task_idh, top_task_idh, task_action, opts)
      end
    end
  end
end

module DTK
  class SSHDriverTest1
    def self.smoketest_start(_task_idh, _top_task_idh, task_action, opts)
      unless callbacks = (opts[:receiver_context] || {})[:callbacks]
        raise Error.new('Unexpected that no calls given')
      end

      if parent = (opts[:receiver_context] || {})[:parent]
        if parent[:status].eql?('failed') || parent[:status].eql?('canceled')
          msg = { msg: parent[:status] }
          callbacks[:on_cancel].call(msg)
          return
        end
      end

      node = task_action[:node]
      node.update_object!(:ref)

      CommandAndControl.poll_to_detect_node_ready(node, opts)
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
