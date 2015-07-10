class DTK::Task::Status::StreamForm::Element
  class TaskStart < self
    def initialize(task)
      super(:task_start,task)
    end
  end
end

