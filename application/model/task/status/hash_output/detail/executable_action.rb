module DTK; class Task::Status; class HashOutput
  class Detail
    class ExecutableAction < self
      def initialize(hash_output, task)
        super
        @executable_action = @task[:executable_action]
        @summary = summary?()
        # TODO: some complexity because :executable_action_type does not distinguish between
        #       config node and action method
        @type = is_component_action_type? ? ComponentActionType : @task[:executable_action_type]
      end
      ComponentActionType = 'ComponentAction'

      def self.add_components_and_actions?(hash_output, task)
        new(hash_output, task).add_components_and_actions?
      end

      def add_components_and_actions?
        return unless @summary
        set?(:executable_action_type, @type)
        set?(:node, node?())
        set?(:components, @type != ComponentActionType ? components?() : nil) 
        set?(:action, @type == ComponentActionType ? action?() : nil)
      end

      private

      def summary?()
        if @executable_action
          ea_class = @executable_action.class
          # TODO: ea_class.status is misnomer; it creates info summary hash about executable_action
          if ea_class.respond_to?(:status)
            ea_class.status(@executable_action, no_attributes: true)
          end
        end
      end

      def is_component_action_type?
        !!action_method?
      end

      def action_method?
        if @executable_action.respond_to?(:action_method?)
          @executable_action.action_method?
        end
      end

      def node?
        if node = @summary[:node]
          if name = node[:name]
            ret = { name: name }
            if type =  node[:type]
              ret.merge!(type: type)
            end
            ret
          end
        end
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
        unless method_name = (action_method? || {})[:method_name]
          Log.error_pp(['Unexpected that no action_method_name', @summary])
          return nil
        end
        { component_name: component_name, method_name: method_name }
      end
      
    end
  end
end; end; end

