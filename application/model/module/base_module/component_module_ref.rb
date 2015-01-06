module DTK; class BaseModule
  class ComponentModuleRef < Hash
    def initialize(component_module,namespace)
      super()
      replace(:component_module => component_module, :remote_namespace => namespace)
    end
    private :initialize

    def component_module()
      self[:component_module]
    end
    
    # returns array of ComponentModuleRefs
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
