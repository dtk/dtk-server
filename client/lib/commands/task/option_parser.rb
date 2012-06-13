module DTK::Client
  class TaskCommand < CommandBaseOptionParser
    CLIParseOptions = Hash.new
    def status(args)
      detail_level=args["detail_level"]||"summary"
      task_id=args["task_id"]

      body = Hash.new
      body["detail_level"] = detail_level
      body["task_id"] = task_id if task_id
      post rest_url("task/state_info"),body
    end
    task_id_optparse_spec = {:name => :task_id, :optparse_spec => ["-T TASK-ID","--task-id TASK-ID", "Task ID"]}

    CLIParseOptions[:status] = {
      :options => 
      [
       task_id_optparse_spec,
       {:name => :detail_level, :optparse_spec => ["-D DETAIL-LEVEL","--detail-level DETAIL-LEVEL", "Detail Level"]}       
      ]
    }

    def commit_changes(args={})
      post rest_url("task/create_task_commit_changes")
    end
    CLIParseOptions[:commit_changes] = {
      :options =>[]
    }

    def execute(args)
      task_id=args["task_id"]
      post rest_url("task/execute"), "task_id" => task_id
    end
    CLIParseOptions[:execute] = {
      :options => [task_id_optparse_spec] 
    }

    def commit_changes_and_execute(args)
      response = commit_changes()
      if response.ok?
        execute("task_id" => response.data["task_id"])
      else
        response
      end
    end
    CLIParseOptions[:commit_changes_and_execute] = {
      :options =>[]
    }

  end
end

