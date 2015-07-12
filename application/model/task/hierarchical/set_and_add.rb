module DTK; class Task
  module HierarchicalMixin
    module SetAndAddMixin
      def add_subtask_from_hash(hash)
        defaults = { status: 'created', action_on_failure: 'abort' }
        new_subtask = Task.new(defaults.merge(hash), c)
        add_subtask(new_subtask)
      end
      
      def add_subtask(new_subtask)
        (self[:subtasks] ||= []) << new_subtask
        new_subtask
      end
      
      def add_subtasks(new_subtasks)
        new_subtasks.each { |new_subtask| (self[:subtasks] ||= []) << new_subtask }
        self
      end
      
      def set_positions!
        self[:position] ||= 1
        return nil if subtasks.empty?
        subtasks.each_with_index do |e, i|
          e[:position] = i + 1
          e.set_positions!()
        end
      end
      
      def set_and_ret_parents_and_children_status!(parent_id = nil)
        self[:task_id] = parent_id
        id = id()
        if subtasks.empty?
          [parent_id: parent_id, id: id, children_status: nil]
        else
          recursive_subtasks = subtasks.map { |st| st.set_and_ret_parents_and_children_status!(id) }.flatten
          children_status = subtasks.inject({}) { |h, st| h.merge(st.id() => 'created') }
          [parent_id: parent_id, id: id, children_status: children_status] + recursive_subtasks
        end
      end

    end
  end
end; end
