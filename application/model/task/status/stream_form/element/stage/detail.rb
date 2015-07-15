module DTK; class Task::Status::StreamForm::Element
  class Stage
    class Detail
      def initialize(stage_elements, hash_opts = {})
        @elements          = stage_elements
        @opts              = Opts.new(hash_opts)
        @stage_level_tasks = stage_elements.map{|el|el.task} 
        @leaf_subtasks     = nil
        @action_results    = nil
      end

      def self.add_detail!(stage_elements, hash_opts = {})
        new(stage_elements, hash_opts).add_detail!()
      end
        
      def add_detail!()
        return if @elements.empty?
        if @opts.add_subtasks?
          add_subtasks!
          if @opts.add_action_results?
            add_action_results!
          end
        end
      end

      private

      # For each stage_level_task, this method computes its nested subtaaks
      # and updates @leaf_subtasks
      def add_subtasks!
        @leaf_subtasks = @stage_level_tasks.inject([]) do |a, stage_level_task|
          hier_task = Task::Hierarchical.get(stage_level_task.id_handle()) 
          if subtasks = hier_task[:subtasks]
            # this is so we have the whole path down to leaf node
            stage_level_task.merge!(subtasks: subtasks)
            a + leaf_subtasks(subtasks)
          else
            a + [hier_task]
          end
        end
      end

      def leaf_subtasks(subtasks)
        subtasks.inject([]) do |a, subtask|
          if children_subtasks = subtask[:subtasks]
            a + leaf_subtasks(children_subtasks)
          else
            a + [subtask]
          end
        end
      end

      def add_action_results!
        if @leaf_subtasks.nil?
          raise Error.new("@leaf_subtasks should be set")
        end
        return if @leaf_subtasks.empty?
        
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
