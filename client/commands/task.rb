require File.expand_path('../core/core', File.dirname(__FILE__))
class R8::Client
  class TaskCommand < CommandBase
    def get_state_info(task_id=nil)
      path = "task/state_info#{task_id ? "/#{task_id.to_s}" : ""}"
      get rest_url(path)
    end
  end
end

conn = R8::Client::Conn.new()

pp conn.task.get_state_info()

    
