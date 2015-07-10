class DTK::Task::Status::StreamForm::Element
  class Stage < self
    def initialize(task)
      super(:stage,task)
    end

    def hash_form()
      super().merge(@task.hash_subset(:display_name,:status,:ended_at))
    end
    #TODO: need to put in logic for no results
    def self.elements(top_level_task,start_stage,end_stage)
      ret = Array.new
      # get one more than the end_stage to check if at end and to be robust againts error where
      # the stage level state is not updated
      tasks = top_level_task.get_ordered_stage_level_tasks(start_stage,end_stage+1)
      if tasks.empty?
        return([TaskEnd.new()])
      end

      reached_end = false
      if tasks.size == 2+end_stage-start_stage
        tasks.pop()
      else
        reached_end = true
      end
      ret = tasks.map{|task|new(task)}
      if reached_end
        ret << TaskEnd.new()
      end

      ret
    end

  end
end
