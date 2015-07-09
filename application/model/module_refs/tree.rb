module DTK
  class ModuleRefs
    # This class is used to build a hierarchical dependency tree and to detect conflicts
    class Tree
      r8_nested_require('tree','collapsed')
      include Collapsed::Mixin

      MISSING_MODULE__REF_TYPE = '-- MISSING MODULE REF --'

      attr_reader :module_branch
      def initialize(module_branch,context=nil)
        @module_branch = module_branch
        @context = context
        # module_refs is hash where key is module_name and
        # value is either nil for a missing reference
        # or it points to a Tree object
        @module_refs = {}
      end
      private :initialize

      # opts can have
      # :components - a set of component instances to contrain what is returned
      def self.create(assembly_instance, opts={})
        assembly_branch = AssemblyModule::Service.get_assembly_branch(assembly_instance)
        components =  opts[:components] || assembly_instance.get_component_instances()
        create_module_refs_starting_from_assembly(assembly_instance,assembly_branch,components)
      end

      def isa_missing_module_ref?
        @context.is_a?(ModuleRef::Missing) && @context
      end

      def isa_module_ref?
        @context.is_a?(ModuleRef) && @context
      end

      def violations?
        missing   = {}
        multi_ns  = {}
        refs      = hash_form()

        refs.each do |k,v|
          if k == :refs
            check_refs(v, missing, multi_ns)
          end
        end

        multi_ns.delete_if{|_k,v| v.size < 2}
        return missing, multi_ns
      end

      def check_refs(refs, missing, multi_ns)
        return unless refs

        refs.each do |name,ref|
          if ref
            namespace = ref[:namespace]
            type = ref[:type]
            if val = multi_ns["#{name}"]
              unless val.include?(namespace)
                val << namespace
                multi_ns.merge!(name => val)
              end
            elsif type && type.to_s.eql?(MISSING_MODULE__REF_TYPE)
              missing.merge!(name => namespace)
            else
              multi_ns.merge!(name => [namespace])
            end
            check_refs(ref[:refs], missing, multi_ns) if ref.key?(:refs)
          else
            # we don't know which namespace this module belongs to, so sending empty namespace
            missing.merge!(name => '')
          end
        end
      end

      def hash_form
        ret = {}
        if @context.is_a?(Assembly)
          ret[:type] = Workspace.is_workspace?(@context) ? 'Workspace' : 'Assembly::Instance'
          ret[:name] = @context.get_field?(:display_name)
        elsif isa_module_ref?()
          ret[:type] = 'ModuleRef'
          ret[:namespace] = namespace()
          if external_ref = external_ref?()
            ret[:external_ref]  = external_ref
          end
        elsif isa_missing_module_ref?()
          ret[:type] = MISSING_MODULE__REF_TYPE
          ret[:namespace] = namespace()
        else
          ret[:type] = @context.class
          ret[:content] = @context
        end

        refs = @module_refs.inject({}) do |h,(module_name,subtree)|
          h.merge(module_name => subtree && subtree.hash_form())
        end
        ret[:refs] = refs unless refs.empty?

        ret
      end

      def add_module_ref!(module_name,child)
        @module_refs[module_name] = child
      end

      def namespace
        namespace?() || (Log.error_pp(['Unexpected that no namespace_info for',self]); nil)
      end

      def namespace?
        if @context.is_a?(ModuleRef)
          @context[:namespace_info]
        elsif @context.is_a?(ModuleRef::Missing)
          @context.namespace
        end
      end

      def external_ref?
        if @context.is_a?(ModuleRef)
          @context[:external_ref]
        end
      end

      def recursive_add_module_refs!(parent_path=[])
        get_children([module_branch()]) do |module_name,namespace,child|
          ns_module_name = self.class.namespace_model_name_path_el(namespace,module_name)
          path = parent_path+[ns_module_name]
          if parent_path.include?(ns_module_name)
            recursive_loop = path.join(' -> ')
            raise ErrorUsage.new("Module '#{ns_module_name}' is in a recursive loop: #{recursive_loop}")
          end
          if child
            add_module_ref!(module_name,child)
            child.recursive_add_module_refs!(path)
          else
            # missing ref to module_name,namespace
            module_branch = nil
            context = ModuleRef::Missing.new(module_name,namespace)
            add_module_ref!(module_name,self.class.new(module_branch,context))
          end
        end
        self
      end

      private

      def self.namespace_model_name_path_el(namespace,module_name)
        namespace ? "#{namespace}:#{module_name}" : module_name
      end

      def self.create_module_refs_starting_from_assembly(assembly_instance,assembly_branch,components)
        # get relevant service and component module branches
        ndx_cmps = {} #components indexed (grouped) by branch id
        components.each do |cmp|
          unless branch_id = cmp.get_field?(:module_branch_id)
            Log.error("Unexpected that :module_branch_id not in: #{cmp.inspect}")
            next
          end
          (ndx_cmps[branch_id] ||= []) << cmp
        end
        cmp_module_branch_ids = ndx_cmps.keys

        sp_hash = {
          cols: ModuleBranch.common_columns(),
          filter: [:oneof,:id,cmp_module_branch_ids]
        }
        cmp_module_branches = Model.get_objs(assembly_instance.model_handle(:module_branch),sp_hash)

        #TODO: extra check we can remove after we refine
        missing_branches = cmp_module_branch_ids - cmp_module_branches.map{|r|r[:id]}
        unless missing_branches.empty?
          Log.error("Unexpected that the following branches dont exist; branches with ids #{missing_branches.join(',')}")
        end

        ret = new(assembly_branch,assembly_instance)
        get_top_level_children(cmp_module_branches,assembly_branch) do |module_name,child|
          if child
            ret.add_module_ref!(module_name,child)
            parent_path = [namespace_model_name_path_el(child.namespace,module_name)]
            child.recursive_add_module_refs!(parent_path)
          else
            Log.error_pp(['Unexpected that in get_top_level_children child can be nil',cmp_module_branches,assembly_branch])
          end
        end
        ret
      end

      # TODO: fix this up because cmp_module_branches already has implict namespace so this is
      # effectively just checking consistency of component module refs
      # and setting of module_branch_id in component insatnces
      def self.get_top_level_children(cmp_module_branches,service_module_branch,&block)
        # get component module refs indexed by module name
        ndx_module_refs = {}
        ModuleRefs.get_component_module_refs(service_module_branch).component_modules.each_value do |module_ref|
          ndx_module_refs[module_ref[:module_name]] ||= module_ref
        end

        # get branches indexed by module_name
        # TODO: can bulk up; look also at using
        # assembly_instance.get_objs(:cols=> [:instance_component_module_branches])
        ndx_mod_name_branches = cmp_module_branches.inject({}) do |h,module_branch|
          h.merge(module_branch.get_module()[:display_name] => module_branch)
        end

        ndx_mod_name_branches.each_pair do |module_name,module_branch|
          module_ref = ndx_module_refs[module_name]
          child = module_ref && new(module_branch,module_ref)
          block.call(module_name,child)
        end
      end

      def get_children(module_branches,_opts={},&block)
        # get component module refs indexed by module name
        ndx_module_refs = {}
        ModuleRefs.get_multiple_component_module_refs(module_branches).each do |cmrs|
          cmrs.component_modules.each_value do |module_ref|
            ndx_module_refs[module_ref[:id]] ||= module_ref
          end
        end
        module_refs = ndx_module_refs.values

        #ndx_module_branches is component module branches indexed by module ref id
        ndx_module_branches = {}
        ModuleRef.find_ndx_matching_component_modules(module_refs).each_pair do |mod_ref_id,cmp_module|
          version = nil #TODO: stub; need to change when treat service isnatnce branches
          ndx_module_branches[mod_ref_id] = cmp_module.get_module_branch_matching_version(version)
        end

        module_refs.each do |module_ref|
          module_branch = ndx_module_branches[module_ref[:id]]
          child = module_branch && self.class.new(module_branch,module_ref)
          block.call(module_ref[:module_name],module_ref[:namespace_info],child)
        end
      end
    end
  end
end
