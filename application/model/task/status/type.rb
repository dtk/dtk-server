class DTK::Task::Status
  module Type
    StatusTypes =
        [
         :created,
         :executing,       
         :succeeded,             
         :failed,
         :cancelled,  
         :preconditions_failed
        ]

    StatusTypes.each do |status|
      class_eval("def self.#{status}(); '#{status}'; end")
    end

    def self.includes_status?(status_array, status)
      status = check_status(status)
      !!status_array.find { |s| send(check_status(status)) == status } 
    end

    def self.has_status?(task, status)
      status = check_status(status)
      task_status = task.get_field?(:status)
      task_status and task_status.to_sym == status
    end

    def self.check_status(status)
      status = status.to_sym
      unless StatusTypes.include?(status)
        fail Error.new("Illegal status '#{status}'")
      end
      status
    end
  end
end
