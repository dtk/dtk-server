module DTK; class Component
  class Dependency
    class Instance < self 
      def self.get_indexed(components)
        ret = Array.new
        return ret if components.empty?
        Component::Instance.augment_with_dependency_info!(components)
        simple_deps = ::DTK::Dependency.find_in_depends_on_form(components)
        link_defs = LinkDef.get(components.map{|cmp|cmp.id_handle()})
        #simple_deps will have all components 
        simple_deps.inject(Hash.new) do |h,(cmp_id,simple)|
          link_def_deps = link_defs.select{|ld|ld[:component_component_id] == cmp_id}
          h.merge(cmp_id => {:simple => simple,:link_def => link_def_deps})
        end
      end

    end
  end
end; end
