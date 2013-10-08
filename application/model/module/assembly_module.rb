module DTK
  class AssemblyModule
    r8_nested_require('assembly_module','component')
    r8_nested_require('assembly_module','service')

    def self.delete_assembly_modules(assembly)
      Component.delete_assembly_modules(assembly)
      Service.delete_assembly_modules(assembly)
    end
  end
end
