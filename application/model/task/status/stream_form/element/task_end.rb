class DTK::Task::Status::StreamForm::Element
  class TaskEnd < self
    def initialize(top_level_task)
      super(:task_end, top_level_task)
    end

    def hash_form()
      super.add_task_fields?(:status, :ended_at)
    end
  end
end
