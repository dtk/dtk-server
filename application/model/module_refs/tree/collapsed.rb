module DTK; class ModuleRefs
  class Tree
    class Collapsed < Hash
      module Mixin
        def collapse(opts = {})
          ret = Collapsed.new
          level = opts[:level] || 1
          @module_refs.each_pair do |module_name, subtree|
            if missing_module_ref = subtree.isa_missing_module_ref?()
              if opts[:raise_errors]
                raise missing_module_ref.error()
              else
                next
              end
            end

            children_module_names = []
            opts_subtree = Aux.hash_subset(opts, [:raise_errors]).merge(level: level + 1)
            subtree.collapse(opts_subtree).each_pair do |subtree_module_name, subtree_els|
              collapsed_tree_els = ret[subtree_module_name] ||= []
              subtree_els.each do |subtree_el|
                unless collapsed_tree_els.find { |el| el == subtree_el }
                  collapsed_tree_els << subtree_el
                end
                subtree_el.children_and_this_module_names().each do |st_module_name|
                  children_module_names << st_module_name unless children_module_names.include?(st_module_name)
                end
              end
            end

            if namespace = subtree.namespace()
              opts_create = { children_module_names: children_module_names }
              if external_ref = subtree.external_ref?()
                opts_create.merge!(external_ref: external_ref)
              end
              (ret[module_name] ||= []) << ModuleRef::Lock::Info.new(namespace, module_name, level, opts_create)
            end
          end
          ret
        end
      end

      # opts[:stratagy] can be
      #  :pick_first_level - if multiple and have first level one then use that otherwise will randomly pick top one
      def choose_namespaces!(opts = {})
        strategy = opts[:strategy] || DefaultStrategy
        if strategy == :pick_first_level
          choose_namespaces__pick_first_level!()
        else
          raise Error.new("Currently not supporting namespace resolution strategy '#{strategy}'")
        end
      end
      DefaultStrategy = :pick_first_level

      def add_implementations!(assembly_instance)
        ndx_impls = get_relevant_ndx_implementations(assembly_instance)
        each_element do |el|
          ndx = impl_index(el.namespace, el.module_name)
          if impl = ndx_impls[ndx]
            el.implementation = impl
          end
        end
        self
      end

      private

      def impl_index(namespace, module_name)
        "#{namespace}:#{module_name}"
      end

      # returns implementations indexed by impl_index
      def get_relevant_ndx_implementations(assembly_instance)
        base_version_field = Implementation.version_field(BaseVersion)
        assembly_version_field = Implementation.version_field(assembly_version(assembly_instance))
        disjuncts = []
        each_element do |el|
          disjunct =
            [:and,
             [:eq, :module_name, el.module_name],
             [:eq, :module_namespace, el.namespace],
             [:oneof, :version, [base_version_field, assembly_version_field]]
            ]
          disjuncts << disjunct
        end
        filter = ((disjuncts.size == 1) ? disjuncts.first : ([:or] + disjuncts))
        sp_hash = {
          cols: [:id, :group_id, :display_name, :repo, :repo_id, :branch, :module_name, :module_namespace, :version],
          filter: filter
        }
        # get the implementations that meet sp_hash, but if have two matches for a module_name/module_namespace pair
        # return just one that matches the assembly version
        ret = {}
        Model.get_objs(assembly_instance.model_handle(:implementation), sp_hash).each do |r|
          ndx = impl_index(r[:module_namespace], r[:module_name])
          # if ndx_ret[ndx], dont replace if what is there is the assembly branch
          unless (ret[ndx] || {})[:version] == assembly_version_field
            ret[ndx] = r
          end
        end
        ret
      end
      BaseVersion = nil

      def assembly_version(assembly_instance)
        ModuleVersion.ret(assembly_instance)
      end

      def choose_namespaces__pick_first_level!(_opts = {})
        each_pair do |module_name, els|
          if els.size > 1
            first_el = els.sort { |a, b| a.level <=> b.level }.first
            #warning only if first_el does not have level 1 and multiple namesapces
            unless first_el.level == 1
              namespaces = els.map(&:namespace).uniq
              if namespaces.size > 1
                Log.error("Multiple namespaces (#{namespaces.join(',')}) for '#{module_name}'; picking one '#{first_el.namespace}'")
              end
            end
            self[module_name] = [first_el]
          end
        end
        self
      end

      def each_element(&block)
        values.each { |els| els.each { |el| block.call(el) } }
      end
    end
  end
end; end
