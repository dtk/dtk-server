module DTK; class Component
  class Instance < self

    def self.add_titles!(cmps)
      ret = cmps
      #TODO: may make this be field in component instance
      cmps_needing_titles = cmps.select do |cmp|
        cmp[:title].nil? and cmp.get_field?(:only_one_per_node) == false
      end
      return ret if cmps_needing_titles.empty?
      sp_hash = {
        :cols => ([:id,:group_id,:display_name,:component_component_id]+Attribute.fields_for_title()).uniq,
        :filter => [:oneof, :component_component_id, cmps_needing_titles.map{|cmp|cmp[:id]}]
      }
      ndx_attrs = hash.new
      get_objs(cmps.first.model_handle(:component),sp_hash).each do |a|
        if title = a.title?()
          ndx_attrs[a[:component_component_id]] = title
        end
      end
      cmps_needing_titles.each do |cmp|
        if title = ndx_attrs[cmp[:id]]
          cmp[:title] = title
        end
      end
      ret
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
