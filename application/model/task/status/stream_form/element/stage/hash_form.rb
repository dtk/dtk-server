module DTK; class Task::Status::StreamForm; class Element
  class Stage
    class HashForm < Element::HashForm
      def initialize(type, task, opts = {})
        super(type, task)
        add_task_fields?(:status, :ended_at, :position)
        unless opts[:donot_add_detail]
          add_nested_detail!
        end
      end
      
      private
      
      def self.create_nested_hash_form(task)
        new(:subtask, task, donot_add_detail: true)
      end
      
      def add_nested_detail!
        set_nested_hash_subtasks!(self, @task)
      end
      
      def set_nested_hash_subtasks!(ret_nested_hash,task)
        if subtasks = task.subtasks?
          ret_nested_hash[:subtasks] = subtasks.map do |st| 
            set_nested_hash_subtasks!(self.class.create_nested_hash_form(st), st) 
          end
        else # subtasks is nil  means that task is leaf task
          LeafTask.add_details!(ret_nested_hash, task)
        end
        ret_nested_hash
      end
      
      class LeafTask
        def initialize(ret_nested_hash, leaf_task)
          @ret_nested_hash = ret_nested_hash
          @leaf_task       = leaf_task
        end
        
        def self.add_details!(ret_nested_hash, leaf_task)
          new(ret_nested_hash, leaf_task).add_details!
        end

        def add_details!
          add_components_and_actions!
          set?(:action_results, action_results())
          # set(:errors, errors())
          @ret_nested_hash
        end
        
        protected
        
        attr_reader :ret_nested_hash, :leaf_task
        
        private

        def action_results
          if action_results = @leaf_task[:action_results]
            action_results.map { |a| Aux.hash_subset(a, ActionResultFields) }
          end
        end
        ActionResultFields = [:status, :stdout, :stderr, :description]

        def set?(key, value)
          unless value.nil?
            @ret_nested_hash[key] = value
          end
        end
        
        def add_components_and_actions!
          ExecutableAction.new(ret_nested_hash, leaf_task).add_components_and_actions!
        end
        
        class ExecutableAction < self
          def initialize(ret_nested_hash, leaf_task)
            super
            if executable_action = @leaf_task[:executable_action]
              ea_class = executable_action.class
              if ea_class.respond_to?(:status)
                @summary = ea_class.status(executable_action, no_attributes: true)
                @type = type(ea_summary)
              else
                Log.error("Unexpected that ea_class.respond_to?(:status) is false for '#{ea_class}'")
              end
            end
          end

          def add_components_and_actions!
            return unless @summary
            set?(:executable_action_type)
            set?(:node, node?())
            set?(:components, (@type != ComponentActionType) && components?())
            set?(:action, (@type == ComponentActionType) && action?())
          end

          # TODO: some complexity because :executable_action_type does not distinguish between 
          #       config node and action method
          def executable_action_type
            has_action_method?() ? ComponentActionType : @leaf_task[:executable_action_type]
          end
          ComponentActionType = 'ComponentAction'
          
          def has_action_method?
            @summary.has_key?(:action_method)
          end
          
          def action_method_name? 
            (@summary[:action_method] || {})[:method_name]
          end
          
          def node?
            name = (@summary[:node] || {})[:name]
            name && { name: name }
          end
          
          def components?
            if component_names = @summary[:components]
              component_names.map { |cmp_name| { name: cmp_name } }
            end
          end
          
          def single_component_name?
            component_names = @summary[:components]
            if component_names and component_names.size == 1
              component_names.first
            end
          end
          
          def action?
            unless component_name = single_component_name?
              Log.error_pp(['Unexpected that not a single component', @summary])
              return nil
            end
            unless method_name = action_method_name?
              Log.error_pp(['Unexpected that no action_method_name', @summary])
              return nil
            end
            { component_name: component_name, method_name: method_name }
          end

        end
      end
    end
  end
end; end; end

