module DTK; class Task::Status::StreamForm::Element
  class Stage
    class Detail
      def initialize(stage_elements)
        @elements          = stage_elements
        @stage_level_tasks = stage_elements.map{|el|el.task} 
        @leaf_subtasks     = nil
      end

      attr_reader :elements

      def self.add_detail!(stage_elements, hash_opts = {})
        new(stage_elements).add_detail!(Opts.new(hash_opts)).elements
      end
        
      def add_detail!(opts = Opts.new)
        ret = self
        return ret if @elements.empty?

        if opts.add_subtasks?
          add_subtasks!
          if opts.add_action_results?
            add_action_results!
          end
        end
        ret
      end

      private

      def add_subtasks!
        @leaf_subtasks = Array.new
        @stage_level_tasks.each_with_index do |task,i|
          add_subtasks_to_stage_level_task!(task,i)
        end
      end

      def add_subtasks_to_stage_level_task!(task, index)
        hier_struct = Task::Hierarchical.get(task.id_handle())
        @stage_level_tasks[index][:subtasks] = hier_struct[:subtasks]
      end

      def add_action_results!
        if @leaf_subtasks.nil?
          raise Error.new("@leaf_subtasks should be set")
        end
        #TODO: stub
pp :add_action_results
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
