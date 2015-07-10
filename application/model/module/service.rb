module DTK
  class ServiceModule < Model
    r8_nested_require('service', 'dsl')
    r8_nested_require('service', 'service_add_on')
    r8_nested_require('module', 'auto_import')

    extend ModuleClassMixin
    extend AutoImport
    include ModuleMixin
    extend DSLClassMixin
    include DSLMixin
    include ModuleRefs::Mixin

    ### standard get methods
    def get_assemblies
      get_objs_helper(:assemblies, :component)
    end

    def get_augmented_assembly_nodes
      get_objs_helper(:assembly_nodes, :node, augmented: true)
    end

    def get_referenced_component_refs
      ndx_ret = {}
      get_objs(cols: [:component_refs]).each do |r|
        cmp_ref = r[:component_ref]
        ndx_ret[cmp_ref[:id]] ||= cmp_ref
      end
      ndx_ret.values
    end

    def assembly_ref(assembly_name, version_field = nil)
      assembly_ref = Namespace.join_namespace(module_namespace(), "#{module_name()}-#{assembly_name}")
      if version_field
        assembly_ref = assembly_ref__add_version(assembly_ref, version_field)
      end
      assembly_ref
    end

    def assembly_ref__add_version(assembly_ref, version_field)
      version = ModuleBranch.version_from_version_field(version_field)
      "#{assembly_ref}--#{version}"
    end

    private :assembly_ref__add_version

    def list_component_modules(opts = Opts.new)
      get_referenced_component_modules(opts).sort { |a, b| a[:display_name] <=> b[:display_name] }
    end

    def get_referenced_component_modules(opts = Opts.new)
      # TODO: alternative is to get this by getting the module_refs
      ret = []
      cmp_refs = get_referenced_component_refs()
      return ret if cmp_refs.empty?
      project = get_project()
      ret = ComponentRef.get_referenced_component_modules(project, cmp_refs)

      if opts.array(:detail_to_include).include?(:versions)
        ndx_versions = get_component_module_refs().version_objs_indexed_by_modules()

        ret.each do |mod|
          if version_obj = ndx_versions[mod.module_name()]
            mod[:version] = version_obj
          end
        end
      end

      ret
    end

    ### end: get methods

    def self.model_type
      :service_module
    end

    def self.filter_list!(rows)
      rows.reject! { |r| Workspace.is_workspace_service_module?(r) }
      rows
    end

    def delete_object
      assembly_templates = get_assembly_templates()

      assoc_assemblies = self.class.get_associated_target_instances(assembly_templates)
      unless assoc_assemblies.empty?
        assembly_names = assoc_assemblies.map { |a| a[:display_name] }
        fail ErrorUsage.new("Cannot delete a service module if one or more of its service instances exist in a target (#{assembly_names.join(',')})")
      end
      repos = get_repos()
      repos.each { |repo| RepoManager.delete_repo(repo) }
      delete_instances(repos.map(&:id_handle))

      # need to explicitly delete nodes since nodes' parents are not the assembly
      Assembly::Template.delete_assemblies_nodes(assembly_templates.map(&:id_handle))

      delete_instance(id_handle())
      { module_name: module_name }
    end

    def delete_version?(version, opts = {})
      delete_version(version, opts.merge(no_error_if_does_not_exist: true))
    end

    def delete_version(version, opts = {})
      ret = { module_name: module_name() }
      unless module_branch  = get_module_branch_matching_version(version)
        if opts[:no_error_if_does_not_exist]
          return ret
        else
          fail ErrorUsage.new("Version '#{version}' for specified component module does not exist")
        end
      end

      unless opts[:donot_delete_meta]
        assembly_templates = module_branch.get_assemblies()
        assoc_assemblies = self.class.get_associated_target_instances(assembly_templates)
        unless assoc_assemblies.empty?
          assembly_names = assoc_assemblies.map { |a| a[:display_name] }
          fail ErrorUsage.new("Cannot delete a service module if one or more of its service instances exist in a target (#{assembly_names.join(',')})")
        end
        Assembly::Template.delete_assemblies_nodes(assembly_templates.map(&:id_handle))
      end

      id_handle = module_branch.id_handle()
      module_branch.delete_instance(id_handle)
      ret
    end

    def get_assembly_instances
      assembly_templates = get_assembly_templates()
      assoc_assemblies = self.class.get_associated_target_instances(assembly_templates)

      assoc_assemblies.each do |assoc_assembly|
        assembly_template = assembly_templates.select { |at| at[:id] == assoc_assembly[:ancestor_id] }
        nodes = assembly_template.first[:nodes]
        assoc_assembly[:nodes] = nodes
      end
    end

    def get_assembly_templates
      sp_hash = {
        cols: [:module_branches]
      }
      mb_idhs = get_objs(sp_hash).map { |r| r[:module_branch].id_handle() }
      opts = {
        filter: [:oneof, :module_branch_id, mb_idhs.map(&:get_id)]
      }
      if project = get_project()
        opts.merge!(project_idh: project.id_handle())
      end
      ndx_ret = Assembly::Template.get(model_handle(:component), opts).inject({}) { |h, r| h.merge(r[:id] => r) }
      Assembly::Template.get_nodes(ndx_ret.values.map(&:id_handle)).each do |node|
        next if node.is_assembly_wide_node?()
        assembly = ndx_ret[node[:assembly_id]]
        (assembly[:nodes] ||= []) << node
      end
      ndx_ret.values
    end

    def info_about(about)
      case about
       when 'assembly-templates'.to_sym
        mb_idhs = get_objs(cols: [:module_branches]).map { |r| r[:module_branch].id_handle() }
        opts = {
          filter: [:oneof, :module_branch_id, mb_idhs.map(&:get_id)],
          detail_level: 'nodes',
          no_module_prefix: true
        }
        if project = get_project()
          opts.merge!(project_idh: project.id_handle())
        end
        Assembly::Template.list(model_handle(:component), opts)
      when :components
        assembly_templates = get_assembly_templates
      else
        fail ErrorUsage.new("TODO: not implemented yet: processing of info_about(#{about})")
      end
    end

    def self.get_project_trees(mh)
      sp_hash = {
        cols: [:id, :display_name, :module_branches]
      }
      sm_branch_info = get_objs(mh, sp_hash)

      ndx_targets = get_ndx_targets(sm_branch_info.map { |r| r[:module_branch].id_handle() })
      mb_idhs = []
      ndx_ret = sm_branch_info.inject({}) do |h, r|
        module_branch = r[:module_branch]
        mb_idhs << module_branch.id_handle()
        mb_id = module_branch[:id]
        content = SimpleOrderedHash.new(
         [
          { name: r.pp_module_branch_name(module_branch) },
          { id: mb_id },
          { targets: ndx_targets[mb_id] || [] },
          { assemblies: [] }
         ])
        h.merge(mb_id => content)
      end

      filter = [:oneof, :module_branch_id, mb_idhs.map(&:get_id)]
      assembly_mh = mh.createMH(:component)
      Assembly::Template.list(assembly_mh, filter: filter, component_info: true).each do |r|
        index = r[:module_branch_id]
        assemblies = ndx_ret[index][:assemblies]
        assemblies << SimpleOrderedHash.new([{ name: r[:display_name] }, { id: r[:id] }, { nodes: format_for_get_project_trees__nodes(r[:nodes]) }])
      end
      ndx_ret.values
    end
    # TODO: use of SimpleOrderedHash above and below was just used to print out in debuging and could be removed
    class << self
      private

      def format_for_get_project_trees__nodes(nodes)
        nodes.map { |n| SimpleOrderedHash.new([{ name: n[:node_name] }, { id: n[:node_id] }, { components: format_for_get_project_trees__cmps(n[:components]) }]) }
      end

      def format_for_get_project_trees__cmps(cmps)
        cmps.map { |cmp| SimpleOrderedHash.new([{ name: cmp[:component_name] }, { id: cmp[:component_id] }, { description: cmp[:description] }]) }
      end
    end

    # targets indexed by service_module
    def self.get_ndx_targets(sm_branch_idhs)
      # TODO: right now: putting in all targets for all service modules;
      ret = []
      return ret if sm_branch_idhs.empty?
      sm_branch_mh = sm_branch_idhs.first.createMH()
      all_targets = Target.list(sm_branch_mh).map do |r|
        SimpleOrderedHash.new([{ name: r[:display_name] }, { id: r[:id] }, { description: r[:description] }])
      end
      sm_branch_idhs.inject({}) do |h, sm_branch_idh|
        h.merge(sm_branch_idh.get_id => all_targets)
      end
    end

    def self.find(mh, name_or_id, library_idh = nil)
      lib_filter = library_idh && [:and, :library_library_id, library_idh.get_id()]
      sp_hash = {
        cols: [:id, :display_name, :library_library_id]
      }

      is_id = Integer(name_or_id) rescue nil

      if is_id
        sp_hash.merge!(filter: [:and, [:eq, :id, name_or_id], lib_filter].compact)
      else
        sp_hash.merge!(filter: [:and, [:eq, :ref, name_or_id], lib_filter].compact)
      end

      rows = get_objs(mh, sp_hash)
      case rows.size
       when 0 then nil
       when 1 then rows.first
       else fail ErrorUsage.new("Cannot find unique service module given service_module_name=#{name_or_id}")
      end
    end

    def self.get_associated_target_instances(assembly_templates)
      ret = []
      return ret if assembly_templates.empty?
      sp_hash = {
        cols: [:id, :display_name, :ancestor_id],
        filter: [:oneof, :ancestor_id, assembly_templates.map { |r| r[:id] }]
      }
      mh = assembly_templates.first.model_handle(:component)
      get_objs(mh, sp_hash)
    end

    # TODO: fix what this returns when fix what update_model_from_dsl returns
    def pull_from_remote__update_from_dsl(repo, module_and_branch_info, _version = nil)
      info = module_and_branch_info #for succinctness
      module_branch_idh = info[:module_branch_idh]
      module_branch = module_branch_idh.create_object().merge(repo: repo)

      update_model_from_dsl(module_branch)
    end

    # returns either parsing error object or nil
    def install__process_dsl(repo, module_branch, local, opts = {})
      unless local.version.nil?
        fail Error.new('Not implemented yet ServiceModule#import__dsl with version not equal to nil')
      end
      response = update_model_from_dsl(module_branch.merge(repo: repo), opts) #repo added to avoid lookup in update_model_from_dsl
      response if ParsingError.is_error?(response)
    end

    private

    # returns the new module branch
    def create_new_version__type_specific(repo_for_new_branch, new_version, _opts = {})
      project = get_project()
      repo_idh = repo_for_new_branch.id_handle()
      module_and_branch_info = self.class.create_ws_module_and_branch_obj?(project, repo_idh, module_name(), new_version, module_namespace_obj())
      module_branch_idh = module_and_branch_info[:module_branch_idh]
      module_branch_idh.create_object()
    end

    # TODO: may want to fix up what this returns after fixing up what update_model_from_dsl returns
    # returns dsl_info
    def update_model_from_clone_changes(_commit_sha, diffs_summary, module_branch, version, opts = {})
      if version.is_a?(ModuleVersion::AssemblyModule)
        assembly = version.get_assembly(model_handle(:component))
        opts_finalize = Aux.hash_subset(opts, [:task_action])
        AssemblyModule::Service.finalize_edit(assembly, opts[:modification_type], self, module_branch, diffs_summary, opts_finalize)
      else
        opts.merge!(ret_dsl_updated_info: {})
        response = update_model_from_dsl(module_branch, opts)
        ret = ModuleDSLInfo.new()
        if ParsingError.is_error?(response)
          ret.dsl_parse_error = response
        else
          ret.merge!(response)
        end
        dsl_updated_info = opts[:ret_dsl_updated_info]
        unless dsl_updated_info.empty?
          ret.dsl_updated_info = dsl_updated_info
        end
        ret
      end
    end

    def publish_preprocess_raise_error?(module_branch_obj)
      # unless get_field?(:dsl_parsed)
      unless module_branch_obj.dsl_parsed?()
        fail ErrorUsage.new('Unable to publish module that has parsing errors. Please fix errors and try to publish again.')
      end

      # get module info for every component in an assembly in the service module
      module_info = get_component_modules_info(module_branch_obj)
      pp [:debug_publish_preprocess_raise_error, :module_info, module_info]
      # check that all component modules are linked to a remote component module
      #       # TODO: ModuleBranch::Location: removed linked_remote; taking out this check until have replacement
      #       unlinked_mods = module_info.reject{|r|r[:repo].linked_remote?()}
      #       unless unlinked_mods.empty?
      #         raise ErrorUsage.new("Cannot export a service module that refers to component modules (#{unlinked_mods.map{|r|r[:display_name]}.join(",")}) not already exported")
      #       end
    end

    # returns [module_branch,component_modules]
    def get_component_modules_info(module_branch)
      filter = [:eq, :module_branch_id, module_branch[:id]]
      component_templates = Assembly.get_component_templates(model_handle(:component), filter)
      mb_mh = model_handle(:module_branch)
      cmp_module_branch_idhs = component_templates.map { |r| r[:module_branch_id] }.uniq.map { |id| mb_mh.createIDH(id: id) }
      ModuleBranch.get_component_modules_info(cmp_module_branch_idhs)
    end
  end
end
