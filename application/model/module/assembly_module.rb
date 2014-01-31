module DTK
  class AssemblyModule
    extend Aux::CommonClassMixin
    r8_nested_require('assembly_module','component')
    r8_nested_require('assembly_module','service')

    def initialize(assembly)
      @assembly = assembly 
    end

    def self.delete_modules?(assembly,opts={})
      Component.new(assembly).delete_modules?()
      Service.new(assembly).delete_module?(opts)
    end

   private
    def self.assembly_module_version(assembly)
      ModuleVersion.ret(assembly)
    end
    def assembly_module_version(assembly=nil)
      assembly ||= @assembly
      unless assembly
        raise Error.new("@assembly should not be null")
      end
      self.class.assembly_module_version(assembly)
    end
  end
end
