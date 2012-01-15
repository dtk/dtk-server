module R8::Client
  class TaskCommand < CommandBaseThor
    desc "status [TASK-ID]", "task status"
    method_option "detail-level",:default => "summary", :aliases => "-d", :desc => "detail level to report task status"

    def status(task_id=nil)
      detail_level = options["detail-level"]
      body = Hash.new
      body["detail_level"] = detail_level
      body["task_id"] = task_id if task_id
      post rest_url("task/state_info"),body
    end
  end
end

