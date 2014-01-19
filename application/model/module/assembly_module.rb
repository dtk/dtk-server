module DTK
  class AssemblyModule
    r8_nested_require('assembly_module','component')
    r8_nested_require('assembly_module','service')

    def self.delete_modules?(assembly,opts={})
      Component.delete_modules?(assembly)
      Service.delete_module?(assembly,opts)
    end

   private
    def self.assembly_module_version(assembly)
      ModuleVersion.ret(assembly)
    end
    def assembly_module_version(assembly)
      self.class.assembly_module_version(assembly)
    end
  end
end
