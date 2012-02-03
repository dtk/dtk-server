module R8::Client
  class TaskCommand < CommandBaseThor

    desc "list","List tasks"
    def list()
      #TODO: just hard coded params now
      search_hash = SearchHash.new()
      search_hash.cols = [:commit_message,:status,:id,:created_at,:started_at,:ended_at]
      search_hash.filter = [:eq, ":task_id", nil] #just top level tasks
      search_hash.set_order_by!(:created_at,"DESC")
      post rest_url("task/list"), search_hash.post_body_hash()
    end

    desc "status [TASK-ID]", "Return task status; if no TASK-ID then information about most recent task"
    method_option "detail-level",:default => "summary", :aliases => "-d", :desc => "detail level to report task status"
    def status(task_id=nil)
      detail_level = options["detail-level"]
      body = Hash.new
      body[:detail_level] = detail_level
      body[:task_id] = task_id if task_id
      post rest_url("task/state_info"),body
    end

    desc "commit-changes", "Commit changes"
    def commit_changes()
      post rest_url("task/create_task_commit_changes")
    end

    desc "execute TASK-ID", "Execute task"
    def execute(task_id)
      post rest_url("task/execute"), "task_id" => task_id
    end

    desc "commit-changes-and-execute", "Commit changes and execute task"
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

