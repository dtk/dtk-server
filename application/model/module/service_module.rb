#
# Copyright (C) 2010-2016 dtk contributors
#
# This file is part of the dtk project.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
module DTK
  class ServiceModule < Model
    require_relative('service_module/dsl')
    require_relative('service_module/service_add_on')
    require_relative('module/auto_import')

    extend ModuleClassMixin
    extend AutoImport
    include ModuleMixin
    extend DSLClassMixin
    include DSLMixin
#    include ModuleRefs::Mixin

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
      assembly_ref = Namespace.join_namespace(module_namespace, "#{module_name}-#{assembly_name}")
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

    ### end: get methods

    def self.model_type
      :service_module
    end

    def self.filter_list!(rows)
      rows.reject! { |r| Workspace.is_workspace_service_module?(r) }
      rows
    end

    # opts can have keys
    #   :from_common_module
    def delete_object(opts = {})
      assembly_templates = get_assembly_templates

      assoc_assemblies = self.class.get_associated_target_instances(assembly_templates)
      unless assoc_assemblies.empty?
        assembly_names = assoc_assemblies.map { |a| a[:display_name] }
        error_msg =
          if opts[:from_common_module]
            "Cannot uninstall a module if one or more service instances (#{assembly_names.join(',')}) created from it exist"
          else
            "Cannot uninstall a module if one or more of its service instances exist (#{assembly_names.join(',')})"
          end
        fail ErrorUsage, error_msg
      end
      repos = get_repos
      repos.each { |repo| RepoManager.delete_repo(repo) }
      delete_instances(repos.map(&:id_handle))

      # need to explicitly delete nodes since nodes' parents are not the assembly
      Assembly::Template.delete_assemblies_nodes(assembly_templates.map(&:id_handle))

      delete_instance(id_handle)
      { module_name: module_name }
    end

    def delete_version?(version, opts = {})
      delete_version(version, opts.merge(no_error_if_does_not_exist: true))
    end

    def delete_version(version, opts = {})
      ret = { module_name: module_name }
      unless module_branch  = get_module_branch_matching_version(version)
        if opts[:no_error_if_does_not_exist]
          return ret
        else
          fail ErrorUsage.new("Version '#{version}' for the specified module does not exist")
        end
      end

      unless opts[:donot_delete_meta]
        assembly_templates = module_branch.get_assemblies
        assoc_assemblies = self.class.get_associated_target_instances(assembly_templates)
        unless assoc_assemblies.empty?
          assembly_names = assoc_assemblies.map { |a| a[:display_name] }
          fail ErrorUsage.new("Cannot uninstall a module if one or more of its service instances exist (#{assembly_names.join(',')})")
        end
        Assembly::Template.delete_assemblies_nodes(assembly_templates.map(&:id_handle))
      end

      module_branch.delete_instance_and_repo_branch
      ret
    end

    def delete_version_or_module(version)
      module_branches = get_module_branches

      if module_branches.size > 1
        delete_version(version)
      else
        unless module_branch = get_module_branch_matching_version(version)
          fail ErrorUsage.new("Version '#{version}' for specified module does not exist!") if version
          fail ErrorUsage.new("Base version for specified module does not exist. You have to specify version you want to delete!")
        end
        delete_object
      end
    end

    def delete_versions_except_base
      ret = { module_name: module_name }

      module_branches = get_module_branches
      module_branches.reject!{ |branch| branch[:version].nil? || branch[:version].eql?('master') }

      module_branches.each do |branch|
        delete_version(branch[:version])
      end

      ret
    end

    def get_assembly_instances
      assembly_templates = get_assembly_templates
      assoc_assemblies = self.class.get_associated_target_instances(assembly_templates)

      assoc_assemblies.each do |assoc_assembly|
        assembly_template = assembly_templates.select { |at| at[:id] == assoc_assembly[:ancestor_id] }
        nodes = assembly_template.first[:nodes]
        assoc_assembly[:nodes] = nodes
      end
    end

    def self.get_assembly_templates(model_handle, opts = {})
      ndx_ret = Assembly::Template.get(model_handle.createMH(:component), opts).inject({}) { |h, r| h.merge(r[:id] => r) }
      # add nodes
      Assembly::Template.get_nodes(ndx_ret.values.map(&:id_handle)).each do |node|
        unless  node.is_assembly_wide_node?
          assembly = ndx_ret[node[:assembly_id]]
          (assembly[:nodes] ||= []) << node
        end
      end
      ndx_ret.values
    end

    def get_assembly_templates(opts = {})
      sp_hash = {
        cols: [:module_branches]
      }
      mb_idhs = get_objs(sp_hash).map { |r| r[:module_branch].id_handle }
      opts.merge!(filter: [:oneof, :module_branch_id, mb_idhs.map(&:get_id)])
      if project = get_project
        opts.merge!(project_idh: project.id_handle)
      end
      self.class.get_assembly_templates(model_handle, opts)
    end

    def self.list_assembly_templates(project)
      # TODO: DTK-2554: put in logic to get only most recent vesions of each module
      ret = add_nodes_size_to_assembly_templates!(get_assembly_templates(project.model_handle))
      # Add display colums
      ret.each do |el|
        el[:display_version] = el[:version] == 'master' ? '' : el[:version]
        el[:module_name]     = el[:service_module][:ref]
      end
      # sort
      ret.sort do |a, b|
        [a[:module_name], a[:display_version], a[:display_name]] <=> [b[:module_name], b[:display_version], b[:display_name]]
      end
    end

    def list_assembly_templates(version = 'master')
      version_filter =
        if version.eql?('master') || version.eql?('base')
          [:or, [:eq, :version, version], [:eq, :version, nil], [:eq, :version, ''], [:eq, :version, 'master']]
        else
          [:eq, :version, version]
        end
      add_nodes_size_to_assembly_templates!(get_assembly_templates(version_filter: version_filter))
    end

    def info_about(about)
      case about
       when 'assembly-templates'.to_sym
        mb_idhs = get_objs(cols: [:module_branches]).map { |r| r[:module_branch].id_handle }
        opts = {
          filter: [:oneof, :module_branch_id, mb_idhs.map(&:get_id)],
          detail_level: 'nodes',
          no_module_prefix: true
        }
        if project = get_project
          opts.merge!(project_idh: project.id_handle)
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

      ndx_targets = get_ndx_targets(sm_branch_info.map { |r| r[:module_branch].id_handle })
      mb_idhs = []
      ndx_ret = sm_branch_info.inject({}) do |h, r|
        module_branch = r[:module_branch]
        mb_idhs << module_branch.id_handle
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
      sm_branch_mh = sm_branch_idhs.first.createMH
      all_targets = Target.list(sm_branch_mh).map do |r|
        SimpleOrderedHash.new([{ name: r[:display_name] }, { id: r[:id] }, { description: r[:description] }])
      end
      sm_branch_idhs.inject({}) do |h, sm_branch_idh|
        h.merge(sm_branch_idh.get_id => all_targets)
      end
    end

    # TODO DTK-2587: deprecate for Module::Service.find_from_id? and Module::Service.find_from_name?
    def self.find(mh, name_or_id, library_idh = nil)
      lib_filter = library_idh && [:and, :library_library_id, library_idh.get_id]
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
       else fail ErrorUsage.new("Cannot find unique module given module name '#{name_or_id}'")
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

    # returns either parsing error object or nil
    def process_dsl_and_ret_parsing_errors(repo, module_branch, local, opts = {})
      if version = local.version
        opts.merge!(module_version: version)
      end
      response = update_model_from_dsl(module_branch.merge(repo: repo), opts) #repo added to avoid lookup in update_model_from_dsl
      response if ParsingError.is_error?(response)
    end

    private

    def add_nodes_size_to_assembly_templates!(assembly_templates_with_nodes)
      self.class.add_nodes_size_to_assembly_templates!(assembly_templates_with_nodes)
    end
    def self.add_nodes_size_to_assembly_templates!(assembly_templates_with_nodes)
      assembly_templates_with_nodes.each do |template|
        nodes_size = 0
        (template[:nodes] || []).each do |node|
          nodes_size += node.is_node_group? ? node.attribute.cardinality : 1
        end
        template[:nodes_size] = nodes_size
      end
      assembly_templates_with_nodes
    end

    # returns the new module branch
    def create_new_version__type_specific(repo_for_new_branch, new_version, opts = {})
      project = get_project
      repo_idh = repo_for_new_branch.id_handle
      module_and_branch_info = self.class.create_ws_module_and_branch_obj?(project, repo_idh, module_name, new_version, module_namespace_obj, opts)
      module_branch_idh = module_and_branch_info[:module_branch_idh]
      module_branch_idh.create_object
    end

    # Returns DTK::ModuleDSLInfo object
    def update_model_from_clone_changes(_commit_sha, diffs_summary, module_branch, version, opts = {})
      ret = ModuleDSLInfo.new
      if version.is_a?(ModuleVersion::AssemblyModule)
        assembly = version.get_assembly(model_handle(:component))
        error_or_nil = update_model_from_dsl__assembly_module(assembly,module_branch, diffs_summary, opts)
        if ParsingError.is_error?(error_or_nil)
          ret.dsl_parse_error = error_or_nil
        end
      else
        opts.merge!(ret_dsl_updated_info: {})
        opts.merge!(module_version: version) if version
        error_or_module_dsl_info = update_model_from_dsl(module_branch, opts)
        if ParsingError.is_error?(error_or_module_dsl_info)
          ret.dsl_parse_error = error_or_module_dsl_info
        else
          ret.aggregate!(error_or_module_dsl_info)
        end
        # TODO: should this be done if there is a parsing error
        dsl_updated_info = opts[:ret_dsl_updated_info]
        unless dsl_updated_info.empty?
          ret.dsl_updated_info = dsl_updated_info
        end
      end
      ret
    end

    def update_model_from_dsl__assembly_module(assembly, module_branch, diffs_summary, opts = {})
      opts_finalize = Aux.hash_subset(opts, [:task_action])
      ParsingError.trap(only_return_error: true) do
        AssemblyModule::Service.finalize_edit(assembly, opts[:modification_type], self, module_branch, diffs_summary, opts_finalize)
      end
    end

    def publish_preprocess_raise_error?(module_branch_obj)
      # unless get_field?(:dsl_parsed)
      unless module_branch_obj.dsl_parsed?
        fail ErrorUsage.new('Unable to publish module that has parsing errors. Please fix errors and try to publish again.')
      end

      # get module info for every component in an assembly in the service module
      module_info = get_component_modules_info(module_branch_obj)
      pp [:debug_publish_preprocess_raise_error, :module_info, module_info]
      # check that all component modules are linked to a remote component module
      #       # TODO: ModuleBranch::Location: removed linked_remote; taking out this check until have replacement
      #       unlinked_mods = module_info.reject{|r|r[:repo].linked_remote?}
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
