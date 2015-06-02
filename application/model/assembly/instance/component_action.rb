module DTK; class  Assembly
  class Instance
    module ComponentActionMixin
      def execute_component_action(component_idh,opts={})
        ComponentAction.new(self,component_idh,opts).execute()
      end
    end

    class ComponentAction
      def initialize(assembly,component_idh,opts={})
        @assembly = assembly
        @component = component_idh.create_object()
        @action_name = opts[:action_name]
        @action_params = opts[:action_parameters]
      end

      def execute()
        # TODO: stub
        pp self
        nil
      end

    end
  end
end; end
