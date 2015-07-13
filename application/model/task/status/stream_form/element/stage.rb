module DTK; class Task::Status::StreamForm::Element
  class Stage < self
    r8_nested_require('stage', 'detail')
    r8_nested_require('stage', 'hash_form')

    def initialize(task)
      super(:stage, task)
    end
    
    def self.elements(top_level_task, start_stage, end_stage, opts = {})
      ret = Array.new
      # Get the stage elements within range start_stage,end_stage
      stage_elements, state = get_stage_elements(top_level_task, start_stage, end_stage)
      Detail.add_detail!(stage_elements, opts)
      case state
        when :all_reached
          stage_elements
        when :task_ended
          stage_elements + [TaskEnd.new(top_level_task)]
        when :not_complete
          # TODO: more advanced which is applicable if multiple stages being requested  
          #       would be to return an updated cursor position
          #       and send back the stages completed
          [NoResults.new()]
        else
          raise Error.new("Unexpected state '#{state}'")
      end
    end

    private

    # returns [stage_elements,state] 
    # where state can be
    #   :task_ended 
    #   :all_reached
    #   :not_complete
    def self.get_stage_elements(top_level_task, start_stage, end_stage)
      # get one more than the end_stage to check if at end and to be robust againts error where
      # the stage level state is not updated
      tasks = top_level_task.get_ordered_stage_level_tasks(start_stage, end_stage + 1)

      if tasks.empty?
        return([Array.new,:task_ended])
      end

      # see if collected more than end_stage and pop it off
      end_plus_1_reached = false
      if tasks.size == 2 + end_stage - start_stage
        if task_started(tasks.last)
          end_plus_1_reached = true
        end
        # pop because we gathered one more than end_stage
        tasks.pop()
      end


      #compute state by looking at last task and whether end_plus_1_reached
      last_task = tasks.last
      state = 
        if task_ended_workflow?(last_task)
          :task_ended
        elsif end_plus_1_reached or task_completed?(last_task)
          :all_reached
        elsif task_completed?(top_level_task)
          # This is for case such as all subtasks complete but top reflects task is cancelled
          :task_ended
        else          
          :not_complete
        end

      stage_elements = tasks.map{|task|new(task)}
      [stage_elements, state]
    end

    def self.task_started(task)
      !task.get_field?(:started_at).nil?
    end

    def self.task_completed?(task)
      status = task.get_field?(:status)
      !status.nil? and status != 'executing'
    end

    def self.task_ended_workflow?(task)
      ['failed','cancelled'].include?(task.get_field?(:status))
    end

  end
end; end



