module DTK
  class ModuleRef
    class Lock < Model
      r8_nested_require('lock','info')
      r8_nested_require('lock','persist')
      
      attr_accessor :info
      def initialize(*args,&block)
        super
        @info = nil
      end
      def locked_branch_sha()
        self[:locked_branch_sha]
      end
      def locked_branch_sha=(sha)
        self[:locked_branch_sha] = sha
      end

      def self.create_from_element(assembly_instance,info)
        ret = create_stub(assembly_instance.model_handle(:module_ref_lock))
        ret.info = info
        ret
      end
      
      def self.persist(module_refs_lock)
        Persist.persist(module_refs_lock)
      end
      
    end
  end
end

=begin
:namespace=>"puppetlabs",
 :module_name=>"stdlib",
 :level=>3,
 :children_module_names=>[],
 :implementation=>
  {:id=>2147790775,
   :group_id=>2147710305,
   :display_name=>"stdlib",
   :repo=>"dtk-user-puppetlabs-stdlib",
   :repo_id=>2147790768,
   :branch=>"workspace-private-dtk-user",
   :module_name=>"stdlib",
   :module_namespace=>"puppetlabs",
   :version=>"master"},
 :module_branch=>
  {:id=>2147790774,
   :group_id=>2147710305,
   :display_name=>"workspace-private-dtk-user",
   :component_id=>2147790773,
   :branch=>"workspace-private-dtk-user",
   :repo_id=>2147790768,
   :current_sha=>"40befe2e2e2f7845145b658299b6874851fe2d6e",
   :version=>"master",
   :dsl_parsed=>true}}
=end
