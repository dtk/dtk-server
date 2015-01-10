module DTK; class ModuleRefs
  class Component < Hash
    def initialize(component_module,namespace)
      super()
      replace(:component_module => component_module, :remote_namespace => namespace)
    end
    private :initialize

    def component_module()
      self[:component_module]
    end
    def namespace?()
      self[:remote_namespace]
    end

    def self.get_dsl_info(module_class,module_branch)
      ModuleRefs::Parse.get_component_module_refs_dsl_info(module_class,module_branch).map do |r|
        new(r[:component_module],r[:remote_namespace])
      end
    end

    def self.get_matching(project_idh,module_names)
      opts = {
        :cols => [:namespace_id,:namespace],
        :filter => [:oneof,:display_name,module_names]
      }
      matching_modules = ComponentModule.get_all_with_filter(project_idh,opts)
      matching_modules.map{|m| new(m[:display_name],m[:namespace][:name])} 
    end
    
    def self.create_from_module_branches?(module_branches)
      ret = nil
      if module_branches.nil? or module_branches.empty?
        return ret 
      end
      mb_idhs = module_branches.map{|mb|mb.id_handle()}
      ModuleBranch.get_namespace_info(mb_idhs).map do |r|
        new(r[:component_module][:display_name],r[:namespace][:display_name])
      end
    end
  end
end; end

