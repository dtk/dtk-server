module DTK; class Component
  class Instance < self

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
