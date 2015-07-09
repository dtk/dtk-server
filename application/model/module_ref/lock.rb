module DTK
  class ModuleRef
    class Lock < Model
      r8_nested_require('lock','info')
      r8_nested_require('lock','persist')

      def self.common_columns
        [:id,:display_name,:group_id,:module_name,:info,:locked_branch_sha]
      end

      attr_accessor :info
      def initialize(*args,&block)
        super
        @info = nil
      end

      def locked_branch_sha
        self[:locked_branch_sha]
      end

      def locked_branch_sha=(sha)
        self[:locked_branch_sha] = sha
      end

      def module_name
        (@info && @info.module_name) || (Log.error_pp(['Unexpected that no module name',self]); nil)
      end

      def self.create_from_element(assembly_instance,info)
        ret = create_stub(assembly_instance.model_handle(:module_ref_lock))
        ret.info = info
        ret
      end

      def self.persist(module_refs_lock)
        Persist.persist(module_refs_lock)
      end

      def self.get(assembly_instance)
        Persist.get(assembly_instance).map(&:reify)
      end

      def reify
        info_hash = self[:info]
        @info = info_hash && Info.create_from_hash(model_handle,info_hash)
        self
      end

    end
  end
end
