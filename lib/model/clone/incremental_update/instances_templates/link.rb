module DTK; class Clone; class IncrementalUpdate
  module InstancesTemplates
    class Link
      attr_reader :instances, :templates, :parent_link
      def initialize(instances, templates, parent_link)
        @instances = instances
        @templates = templates
        @parent_link = parent_link
      end

      def instance_model_handle
        # want parent information
        @parent_link.instance.child_model_handle(instance_model_name())
      end

      private

      def instance_model_name
        #all templates and instances should have same model name so just need to find one
        #one of these wil be non null
        (@instances.first || @templates.first).model_name
      end
    end
  end
end; end; end
