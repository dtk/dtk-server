module DTK; class Task::Status::StreamForm; class Element
  class Stage
    class HashForm < Element::HashForm
      def initialize(element)
        super(element)
        add_task_fields?(:status, :ended_at, :position)
        add_nested_detail!()
      end

      private
        
      def add_nested_detail!()
        @task.get_leaf_subtasks.each { |leaf_task| add_detail_from_leaf_task!(leaf_task)}
      end

      def add_detail_from_leaf_task!(leaf_task)
        if action_results = leaf_task[:action_results]
          self[:action_results] ||= []
          self[:action_results] += action_results
        end
      end
    end
  end
end; end; end


