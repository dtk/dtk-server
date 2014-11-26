module DTK; class Clone;
  class IncrementalUpdate
    class Dependency < self
      def initialize(cmp_template_links)
        @cmp_template_links = cmp_template_links
      end
      def update?()
        links = get_instance_template_links()
        links.update_model(self.class) unless links.empty?
      end
      def self.equal?(instance,template)
        false
      end
     private
      def get_instance_template_links()
        ret = InstancesTemplates::Links.new()
        component_idhs = @cmp_template_links.all_id_handles()
        ndx_dependencies = ::DTK::Component::Dependency.get_nested_dependencies(component_idhs).inject(Hash.new) do |h,r|
          h.merge(r[:id] => r[:dependencies])
        end
        @cmp_template_links.each do |cmp_link|
          cmp_instance = cmp_link.instance
          dep_instances = cmp_instance && ndx_dependencies[cmp_instance.id]
          cmp_template = cmp_link.template
          dep_templates = cmp_template && ndx_dependencies[cmp_template.id]
          ret.add?(dep_instances,dep_templates,cmp_link)
        end
        ret
      end
    end
  end
end; end
