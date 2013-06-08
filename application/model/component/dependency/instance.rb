module DTK; class Component
  class Dependency
    class Instance < self 
      def self.get_indexed(cmp_instance_idhs,opts=Opts.new)
        ret = Array.new
        return ret if cmp_instance_idhs.empty?
        sample_idh = cmp_instance_idhs.first
        sp_hash = {
          :cols => [:id,:inherited_dependencies, :extended_base, :component_type],
          :filter => [:oneof, :id, cmp_instance_idhs.map{|idh|idh.get_id()}]
        }
        cmp_mh = cmp_instance_idhs.first.createMH()
        components = Model.get_objs(cmp_mh,sp_hash)
        simple_deps = find_component_simple_dependencies(components)
        if opts[:return] == :component_type_and_simple_dependencies
          return simple_deps
        end

        component_template_idhs = components.map{|r|r.id_handle(:id => r[:parent_component][:id])}.uniq
        link_defs = LinkDef.get(component_template_idhs)
        ndx_cmp_to_template = components.inject(Hash.new){|h,r|h.merge(r[:id] => r[:parent_component][:id])}
        #simple_deps will have all components 
        simple_deps.inject(Hash.new) do |h,(cmp_id,v)|
          simple_deps = v[:component_dependencies]||[]
          link_def_deps = link_defs.select{|ld|ld[:component_component_id] == ndx_cmp_to_template[cmp_id]}
          h.merge(cmp_id => {:simple => simple_deps,:link_def => link_def_deps})
        end
      end

    end
  end
end; end
