module DTK
  class AssemblyModule
    r8_nested_require('assembly_module','component')
    r8_nested_require('assembly_module','service')

    def self.delete_modules?(assembly)
      Component.delete_modules?(assembly)
      Service.delete_module?(assembly)
    end
  end
end
