module DTK; class Clone; 
  module IncrementalUpdate
    class Dependency 
      def initialize(cmp_template_links)
        @cmp_template_links = cmp_template_links
      end
      def update?()
        links = get_instance_template_links()
        links.update_model() unless links.empty?
      end
     private
      def get_instance_template_links()
        ret = InstancesTemplatesLink.new()
        component_idhs = @cmp_template_links.all_id_handles()
        ndx_dependencies = ::DTK::Component.get_nested_dependencies(component_idhs).inject(Hash.new) do |h,r|
          h.merge(r[:id] => r[:dependencies])
        end
        @cmp_template_links.each do |cmp_link|
          cmp_instance = cmp_link[:instance]
          dep_instances = cmp_instance && ndx_dependencies[cmp_instance.id]
          dep_templates = cmp_link[:template] && ndx_dependencies[cmp_link[:template].id]
          ret.add(dep_instances,dep_templates,cmp_instance)
        end
        ret
      end
    end
  end
end; end
