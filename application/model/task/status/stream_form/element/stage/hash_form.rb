module DTK; class Task::Status::StreamForm; class Element
  class Stage
    class HashForm < Element::HashForm
      def initialize(element)
        super(element)
        @subtasks = @task[:subtasks] || []
        add_task_fields?(:status, :ended_at, :position)
        add_nested_detail!()
      end

      private
        
      def add_nested_detail!()
        return if @subtasks.empty?
        pp :add_nested_detail
      end
    end
  end
end; end; end


