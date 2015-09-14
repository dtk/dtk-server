module DTK; class ConfigAgent; module Adapter
  class NoOp < ConfigAgent
    def ret_msg_content(_config_node, opts = {})
      {}
    end

    def execute(_task_action)
      results = {
        statuscode: 0,
        statusmsg:  'OK',
        data:       { status: :succeeded}
      }
    end
  end
end; end; end
