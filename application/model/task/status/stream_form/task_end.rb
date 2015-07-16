class DTK::Task::Status::StreamForm
  class TaskEnd < self
    def initialize(top_level_task)
      super(:task_end, top_level_task)
    end

    private

    def hash_output_opts
      { task_fields: [:started_at, :ended_at, :status] }
    end
  end
end
