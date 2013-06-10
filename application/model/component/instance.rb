module DTK; class Component
  class Instance < self
    def self.augment_with_dependency_info!(cmps)
      return cmps if cmps.empty?
      sp_hash = {
        :cols => [:id,:group_id,:component_component_id,:search_pattern,:type,:description,:severity],
        :filter => [:oneof,:component_component_id,cmps.map{|cmp|cmp.id()}]
      }
      dep_mh = cmps.first.model_handle(:dependency)

      deps = get_objs(dep_mh,sp_hash)
      return cmps if deps.empty?
      ndx_cmps = cmps.inject(Hash.new){|h,cmp|h.merge(cmp[:id] => cmp)}
      deps.each do |dep|
        cmp = ndx_cmps[dep[:component_component_id]]
        (cmp[:dependencies] ||= Array.new) << dep
      end
      cmps
    end

    #TODO: may be able to deprecate below seeing that dependencies are on instances
    def self.get_components_with_dependency_info(cmp_idhs)
      ret = Array.new
      return ret if cmp_idhs.empty?
      sp_hash = {
        :cols => [:id,:inherited_dependencies, :extended_base, :component_type],
        :filter => [:oneof, :id, cmp_idhs.map{|idh|idh.get_id()}]
      }
      cmp_mh = cmp_idhs.first.createMH()
      Model.get_objs(cmp_mh,sp_hash)
    end

    def self.print_form(component)
      component.get_field?(:display_name).gsub(/__/,"::")
    end

    def self.version_print_form(component)
      ModuleBranch.version_from_version_field(component.get_field?(:version))
    end

  end
end; end
