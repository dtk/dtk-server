module DTK; class Component
  class Dependency
    class Instance < self 
      def self.get_indexed(cmp_instance_idhs)
        ret = Array.new
        return ret if cmp_instance_idhs.empty?
        components = Component::Instance.get_components_with_dependency_info(cmp_instance_idhs)
        simple_deps = ::DTK::Dependency.find_ndx_derived_order(components)
        component_template_idhs = components.map{|r|r.id_handle(:id => r[:parent_component][:id])}.uniq
        link_defs = LinkDef.get(component_template_idhs)
        ndx_cmp_to_template = components.inject(Hash.new){|h,r|h.merge(r[:id] => r[:parent_component][:id])}
        #simple_deps will have all components 
        simple_deps.inject(Hash.new) do |h,(cmp_id,simple)|
          link_def_deps = link_defs.select{|ld|ld[:component_component_id] == ndx_cmp_to_template[cmp_id]}
          h.merge(cmp_id => {:simple => simple,:link_def => link_def_deps})
        end
      end

    end
  end
end; end
