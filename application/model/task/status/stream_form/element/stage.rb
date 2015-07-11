class DTK::Task::Status::StreamForm::Element
  class Stage < self
    def initialize(task)
      super(:stage,task)
    end
    
    def hash_form
      super().add_elements?(:status,:ended_at,:position)
    end

    def self.elements(top_level_task,start_stage,end_stage)
      ret = Array.new
      # get one more than the end_stage to check if at end and to be robust againts error where
      # the stage level state is not updated
      tasks = top_level_task.get_ordered_stage_level_tasks(start_stage,end_stage+1)
      task_end = nil
      if tasks.size == 2+end_stage-start_stage
        tasks.pop()
      else
        task_end = TaskEnd.new(top_level_task)
      end
      tasks.map{|task|new(task)} + (task_end ? [task_end] : [])
    end
  end
end
