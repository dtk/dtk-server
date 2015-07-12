module DTK
  class Task 
    class Hierarchical < self
      r8_nested_require('hierarchical', 'get')
      r8_nested_require('hierarchical', 'update')
      r8_nested_require('hierarchical', 'persistence')
      r8_nested_require('hierarchical', 'set_and_add')
      extend GetClassMixin
    end

    module HierarchicalMixin
      include GetMixin
      include UpdateMixin
      include PersistenceMixin
      include SetAndAddMixin

      def is_status?(status)
        self[:status] == status || subtasks.find{ |subtask| subtask[:status] == status }
      end
      
      def component_actions
        if executable_action().is_a?(Action::ConfigNode)
          action = executable_action()
          action.component_actions().map { |ca| action[:node] ? ca.merge(node: action[:node]) : ca }
        else
          subtasks.map(&:component_actions).flatten
        end
      end
      
      def node_level_actions
        if executable_action().is_a?(Action::NodeLevel)
          action = executable_action()
          return action.component_actions().map { |ca| action[:node] ? ca.merge(node: action[:node]) : ca }
        else
          subtasks.map(&:node_level_actions).flatten
        end
      end
      
      def unroll_tasks
        [self] + subtasks.map(&:unroll_tasks).flatten
      end
      
      def subtasks
        self[:subtasks] || []
      end
      
      def subtasks?
        self[:subtasks]
      end
      
      def render_form
        # may be different forms; this is one that is organized by node_group, node, component, attribute
        task_list = render_form_flat(true)
        # TODO: not yet teating node_group
        Task.render_group_by_node(task_list)
      end
      
      protected
      
      def render_form_flat(top = false)
        # prune out all (sub)tasks except for top and  executable
        return render_executable_tasks() if executable_action(no_error_if_nil: true)
        (top ? [render_top_task()] : []) + subtasks.map(&:render_form_flat).flatten
      end
      
      def hierarchical_task_idhs
        [id_handle()] + subtasks.map{|r|r.hierarchical_task_idhs()}.flatten
      end

    end
  end
end
