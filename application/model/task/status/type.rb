class DTK::Task::Status
  module Type
    StatusTypes =
        [
         'created',
         'executing',       
         'succeeded',             
         'failed',
         'cancelled',  
         'preconditions_failed'
        ]

    StatusTypes.each do |status|
      class_eval("def self.#{status}(); '#{status}'; end")
      class_eval("def self.has_status_#{status}(task_status); '#{status}' == check_status(task_status); end")
    end

    def self.includes_status?(status_array, status)
      status = check_status(status)
      !!status_array.find { |s| send(check_status(s)) == status } 
    end

    def self.task_has_status?(task, status)
      status = check_status(status)
      task_status = task.get_field?(:status)
      task_status and task_status.to_s == status
    end


    def self.is_workflow_ending_status?(status)
      [:failed, :cancelled, :preconditions_failed].include?(check_status(status))
    end

    private

    def self.check_status(status)
      return nil unless status
      status = status.to_s
      unless StatusTypes.include?(status)
        fail Error.new("Illegal status '#{status}'")
      end
      status
    end
  end
end
