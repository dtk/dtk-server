module DTK; class Task::Status::StreamForm::Element
  class Stage
    class Detail
      def initialize(stage_elements, hash_opts = {})
        @stage_elements     = stage_elements
        @stage_level_tasks  = stage_elements.map { |el| el.task } 
      end

      # stage_elements get updated through updates to @stage_level_tasks
      def self.add_detail!(stage_elements, hash_opts = {})
        new(stage_elements, hash_opts).add_detail!(Opts.new(hash_opts))
      end
      def add_detail!(opts)
        if opts.add_subtasks?
          leaf_subtasks = add_subtasks_and_return_leaf_subtasks!
          ndx_leaf_subtasks = leaf_subtasks.inject({}) { |h, t| h.merge(t.id => t) }
          if opts.add_action_results?
            add_action_results!(ndx_leaf_subtasks)
          end
        end
      end

      private

      # For each stage_level_task, this method computes its nested subtasks
      # and returns the set of
      def add_subtasks_and_return_leaf_subtasks!
        @stage_level_tasks.inject([]) do |a, stage_level_task|
          leaf_subtasks([Task::Hierarchical.get(stage_level_task.id_handle())], add_subtasks_to: stage_level_task)
        end
      end

      def leaf_subtasks(tasks, opts = {})
        tasks.inject([]) do |a, task|
          if subtasks = task[:subtasks]
            if stage_level_task = opts[:add_subtasks_to]
              stage_level_task.merge!(subtasks: subtasks)
            end
            a + leaf_subtasks(subtasks)
          else
            a + [task]
          end
        end
      end

      def add_action_results!(ndx_leaf_subtasks)
        return if ndx_leaf_subtasks.empty?
        ndx_action_results = Task.get_ndx_logs(ndx_leaf_subtasks.values.map { |t| t.id_handle() })
        ndx_action_results.each_pair do |task_id, action_results|
          ndx_leaf_subtasks[task_id].merge!(action_results: action_results)
        end
      end

      class Opts < ::Hash
        def initialize(hash_opts = {})
          super()
          replace(hash_opts)
        end

        def add_subtasks?
          !([:action_results, :subtasks] & (detail().keys)).empty?
        end

        def add_action_results?
          detail().has_key?(:action_results)
        end

        private
          
        def detail
          self[:element_detail] || {}
        end
      end
    end
  end
end; end
