require File.expand_path('../core/core', File.dirname(__FILE__))
module R8::Client
  class TaskCommand < CommandBase
    def status(task_id=nil)
      body = Hash.new
      path = "task/state_info#{task_id ? "/#{task_id.to_s}" : ""}"
      post rest_url(path),body
    end

    def commit_changes()
      post rest_url("task/create_task_commit_changes")
    end

    def execute(task_id)
      post rest_url("task/execute"), "task_id" => task_id
    end

    def commit_changes_and_execute()
      response = commit_changes()
      if response.ok?
        execute(response.data["task_id"])
      else
        response
      end
    end
  end
end

