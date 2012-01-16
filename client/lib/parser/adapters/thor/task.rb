module R8::Client
  class TaskCommand < CommandBaseThor

    desc "status [TASK-ID]", "task status"
    method_option "detail-level",:default => "summary", :aliases => "-d", :desc => "detail level to report task status"
    def status(task_id=nil)
      detail_level = options["detail-level"]
      body = Hash.new
      body[:detail_level] = detail_level
      body[:task_id] = task_id if task_id
      post rest_url("task/state_info"),body
    end

    desc "commit_changes", "commit changes"
    def commit_changes()
      post rest_url("task/create_task_commit_changes")
    end

    desc "execute [TASK-ID]", "execute task"
    def execute(task_id)
      post rest_url("task/execute"), "task_id" => task_id
    end

    desc "commit_changes_and_execute", "commit changes and execute task"
    def commit_changes_and_execute()
      response = commit_changes()
      if response.ok?
        execute(response.data["task_id"])
      else
        response
      end
    end

    desc "list","List tasks"
    def list()
      search_hash = {
        :columns => [:id,:display_name,:updated_at],
        :filter=>[:eq, ":task_id", nil] #just top level tasks
      }
      post rest_url("task/list"), {:search => JSON.generate(search_hash)}
    end
  end
end

