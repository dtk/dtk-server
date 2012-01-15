module R8::Client
  class TaskCommand < CommandBase
    desc "status", "task status"
    method_option "detail-level",:default => "summary", :aliases => "-d", :desc => "detail level to report task status"
    method_option "task-id", :aliases => "-d", :desc => "Task ID"

    def status
      detail_level = options["detail-level"]
      task_id = options["task-id"]

      body = Hash.new
      body["detail_level"] = detail_level
      body["task_id"] = task_id if task_id
      post rest_url("task/state_info"),body
    end
  end
end

