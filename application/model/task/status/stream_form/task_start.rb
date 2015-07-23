class DTK::Task::Status::StreamForm
  class TaskStart < self
    def initialize(task)
      super(:task_start, task)
    end

    private

    def hash_output_opts
      { task_fields: [:started_at, :display_name] }
    end
  end
end

