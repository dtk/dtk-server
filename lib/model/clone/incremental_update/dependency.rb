module DTK; class Clone; 
  module IncrementalUpdate
    class Dependency 
      def initialize(cmp_template_links)
        @cmp_template_links = cmp_template_links
      end
      def update?()
        links = get_instance_template_links()
      end
     private
      def get_instance_template_links()
        component_idhs = @cmp_template_links.all_id_handles()
        nested_dependencies = ::DTK::Component.get_nested_dependencies(component_idhs)
        pp nested_dependencies

      end
    end
  end
end; end
