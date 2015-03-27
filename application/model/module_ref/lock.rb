module DTK
  class ModuleRef
    class Lock < Model
      r8_nested_require('lock','info')

      attr_accessor :info
      def self.create_from_element(assembly_instance,info)
        ret = create_stub(assembly_instance.model_handle(:module_ref_lock))
        ret.info = info
        ret
      end
    end
  end
end
