module DTK; class Task
  class Template
    class TaskActionNotFoundError < ErrorUsage
     def initialize(task_action)
       msg = "The Workflow action '#{task_action}' does not exist"
       super(msg)
      end
    end
  end
end; end
