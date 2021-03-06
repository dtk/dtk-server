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
  class AssemblyController < AuthController
    helper :assembly_helper
    helper :task_helper

    include Assembly::Instance::Action

    #### create and delete actions ###
    # TODO: rename to delete_and_destroy
    def rest__delete
      assembly_id, subtype = ret_assembly_params_id_and_subtype()
      if subtype == :template
        # returning module_repo_info so client can update this in its local module
        rest_ok_response Assembly::Template.delete_and_ret_module_repo_info(id_handle(assembly_id))
      else #subtype == :instance
        Assembly::Instance.delete(id_handle(assembly_id), destroy_nodes: true, uninstall: true)
        rest_ok_response
      end
    end

    def rest__delete_using_workflow
      assembly  = ret_assembly_instance_object()

      opts = Opts.new(delete_action: 'delete', delete_params: [assembly.id_handle()])
      opts.merge!(recursive: true) if ret_request_params(:recursive)
      opts.merge!(uninstall: true)

      rest_ok_response assembly.exec__delete(opts)
    end

    def rest__purge
      workspace = ret_workspace_object?()
      workspace.purge(destroy_nodes: true)
      rest_ok_response
    end

    def rest__destroy_and_reset_nodes
      assembly = ret_assembly_instance_object()
      assembly.destroy_and_reset_nodes()
      rest_ok_response
    end

    def rest__remove_from_system
      assembly = ret_assembly_instance_object()
      Assembly::Instance.delete(assembly.id_handle(), uninstall: true)
      rest_ok_response
    end

    def rest__set_target
      workspace = ret_workspace_object?()
      target = create_obj(:target_id, Target::Instance)
      workspace.set_target(target)
      rest_ok_response
    end

    def rest__delete_node
      assembly = ret_assembly_instance_object()
      node_idh = ret_node_or_group_member_id_handle(:node_id, assembly)
      assembly.delete_node(node_idh, destroy_nodes: true)
      rest_ok_response
    end

    def rest__delete_node_using_workflow
      assembly = ret_assembly_instance_object()
      node_idh = ret_node_or_group_member_id_handle(:node_id, assembly)
      opts = Opts.new(delete_action: 'delete_node', delete_params: [node_idh])

      if running_task = most_recent_task_is_executing?(assembly)
        fail ErrorUsage, "Task with id '#{running_task.id}' is already running in assembly. Please wait until task is complete or cancel task."
      end

      rest_ok_response assembly.exec__delete_node(node_idh, opts)
    end

    def rest__delete_node_group
      assembly = ret_assembly_instance_object()
      node_idh = ret_node_or_group_member_id_handle(:node_id, assembly)
      assembly.delete_node_group(node_idh)
      rest_ok_response
    end

    def rest__delete_node_group_using_workflow
      assembly = ret_assembly_instance_object()
      node_idh = ret_node_or_group_member_id_handle(:node_id, assembly)
      opts = Opts.new(delete_action: 'delete_node_group', delete_params: [node_idh])

      if running_task = most_recent_task_is_executing?(assembly)
        fail ErrorUsage, "Task with id '#{running_task.id}' is already running in assembly. Please wait until task is complete or cancel task."
      end

      rest_ok_response assembly.exec__delete_node_group(node_idh, opts)
    end

    def rest__get_node_groups
      assembly = ret_assembly_instance_object()
      rest_ok_response assembly.get_node_groups()
    end

    def rest__get_nodes_without_node_groups
      assembly = ret_assembly_instance_object()
      rest_ok_response assembly.get_nodes__expand_node_groups(remove_node_groups: true)
    end

    # TODO: Aldin - need refactoring
    def rest__delete_component_using_workflow
      assembly    = ret_assembly_instance_object()
      params_hash = ret_params_hash(:commit_msg, :task_action, :task_params, :start_assembly, :skip_violations, :noop_if_no_action)

      params_hash[:task_params] = params_hash[:task_params].is_a?(String) ? Hash.new : params_hash[:task_params]

      node_id = ret_node_id(:node_id, assembly) if ret_request_params(:node_id)

      component_id = ret_non_null_request_params(:component_id)
      assembly_id = assembly.id()
      cmp_full_name = ret_request_params(:cmp_full_name)

      # cmp_name, namespace = ret_non_null_request_params(:component_id, :namespace)
      cmp_name, namespace = ret_request_params(:component_id, :namespace)

      assembly_idh = assembly.id_handle()
      cmp_mh = assembly_idh.createMH(:component)

      if cmp_full_name && node_id
        component = Component.ret_component_with_namespace_for_node(cmp_mh, cmp_name, node_id, namespace, assembly)
        fail ErrorUsage.new("Component with identifier (#{namespace.nil? ? '' : namespace + ':'}#{cmp_name}) does not exist!") unless component

        cmp_idh = component.id_handle()
      else
        cmp_idh = id_handle(component_id, :component)
        params_hash[:cmp_idh] = cmp_idh
      end
      opts = Opts.new(delete_action: 'delete_component', delete_params: [cmp_idh, node_id])

      rest_ok_response assembly.exec__delete_component(params_hash, opts)
    end

    def rest__delete_component
      node_id  = nil
      assembly = ret_assembly_instance_object()

      # Retrieving node_id to validate if component belongs to node when delete-component invoked from component-level context
      node_id = ret_node_id(:node_id, assembly) if ret_request_params(:node_id)

      component_id = ret_non_null_request_params(:component_id)
      assembly_id = assembly.id()
      cmp_full_name = ret_request_params(:cmp_full_name)

      # cmp_name, namespace = ret_non_null_request_params(:component_id, :namespace)
      cmp_name, namespace = ret_request_params(:component_id, :namespace)

      assembly_idh = assembly.id_handle()
      cmp_mh = assembly_idh.createMH(:component)

      if cmp_full_name && node_id
        component = Component.ret_component_with_namespace_for_node(cmp_mh, cmp_name, node_id, namespace, assembly)
        fail ErrorUsage.new("Component with identifier (#{namespace.nil? ? '' : namespace + ':'}#{cmp_name}) does not exist!") unless component

        cmp_idh = component.id_handle()
      else
        cmp_idh = id_handle(component_id, :component)
      end

      assembly.delete_component(cmp_idh, node_id)
      rest_ok_response
    end

    #### end: create and delete actions ###
    #### list and info actions ###
    def rest__info
      assembly = ret_assembly_object()
      node_id, component_id, attribute_id, return_json, only_node_group_info = ret_request_params(:node_id, :component_id, :attribute_id, :json_return, :only_node_group_info)

      opts = { remove_assembly_wide_node: true }
      opts.merge!(only_node_group_info: true) if only_node_group_info
      if return_json.eql?('true')
        rest_ok_response assembly.info(node_id, component_id, attribute_id, opts)
      else
        rest_ok_response assembly.info(node_id, component_id, attribute_id, opts), encode_into: :yaml
      end
    end

    def rest__list_component_module_diffs
      module_id, workspace_branch, module_branch_id, repo_id = ret_request_params(:module_id, :workspace_branch, :module_branch_id, :repo_id)
      repo          = id_handle(repo_id, :repo).create_object()
      project       = get_default_project()
      module_branch = id_handle(module_branch_id, :module_branch).create_object()

      project_idh = project.id_handle()
      opts = Opts.new(project_idh: project_idh)

      rest_ok_response AssemblyModule::Component.list_remote_diffs(model_handle(), module_id, repo, module_branch, workspace_branch, opts)
    end

    # TODO: may be cleaner if we break into list_nodes, list_components with some shared helper functions
    def rest__info_about
      node_id, component_id, attribute_id, detail_level, detail_to_include = ret_request_params(:node_id, :component_id, :attribute_id, :detail_level, :detail_to_include)
      assembly, subtype = ret_assembly_params_object_and_subtype()
      response_opts     = {}

      node_id           = nil if node_id.is_a?(String) && node_id.empty?
      component_id      = nil if component_id.is_a?(String) && component_id.empty?
      attribute_id      = nil if attribute_id.is_a?(String) && attribute_id.empty?

      if node_id && !(node_id =~ /^[0-9]+$/)
        node_id = "#{ret_node_id(:node_id, assembly)}"
      end

      if component_id && !(component_id =~ /^[0-9]+$/)
        component_id = "#{ret_component_id(:component_id, assembly, filter_by_node: true)}"
      end

      if format = ret_request_params(:format)
        format = format.to_sym
        unless SupportedFormats.include?(format)
          fail ErrorUsage.new("Illegal format (#{format}) specified; it must be one of: #{SupportedFormats.join(',')}")
        end
      end

      about = ret_non_null_request_params(:about).to_sym
      unless AboutEnum[subtype].include?(about)
        fail ErrorUsage::BadParamValue.new(:about, AboutEnum[subtype])
      end

      opts = Opts.new(detail_level: detail_level)
      additional_filter_proc = nil
      if about == :attributes
        if format == :yaml
          opts.merge!(settings_form: true, mark_unset_required: true)
        else
          opts.merge!(truncate_attribute_values: true, mark_unset_required: true)
        end

        opts.merge!(:raise_if_no_attribute => true, :attribute_id => attribute_id) if attribute_id

        additional_filter_opts = {
          tags: ret_request_params(:tags),
          editable: 'editable' == ret_request_params(:attribute_type)
        }

        additional_filter_proc = Proc.new do |e|
          attr = e[:attribute]
          (!attr.is_a?(Attribute)) || !attr.filter_when_listing?(additional_filter_opts)
        end
      elsif about == :components
        # if not at node level filter out components on node group members (target_refs)
        unless node_id
          additional_filter_proc = Proc.new do |e|
            node = e[:node]
            (!node.is_a?(Node)) || !Node::TargetRef.is_target_ref?(node)
          end
        end
      end

      opts[:filter_proc] = Proc.new do |e|
        if element_matches?(e, [:node, :id], node_id) &&
            element_matches?(e, [:attribute, :component_component_id], component_id) &&
              attribute_element_matches?(e, attribute_id)
                if additional_filter_proc.nil? || additional_filter_proc.call(e)
                  e
                end
        end
      end

      opts.add_return_datatype!()
      if detail_to_include
        opts.merge!(detail_to_include: detail_to_include.map(&:to_sym))
        opts.add_value_to_return!(:datatype)
      end

      if node_id
        opts.merge!(node_cmp_name: true)
      end

      data          = assembly.info_about(about, opts)
      datatype      = opts.get_datatype
      response_opts = {}

      if format == :yaml
        response_opts.merge!(encode_into: :yaml)
      else
        response_opts.merge!(datatype: datatype)
      end

      rest_ok_response data, response_opts
    end
    SupportedFormats = [:yaml]

    def rest__info_about_task
      assembly = ret_assembly_instance_object()
      task_action = ret_request_params(:task_action)
      response = Task::Template.get_serialized_content(assembly, task_action)
      response_opts = {}
      if response
        response_opts.merge!(encode_into: :yaml)
      else
        response = { message: "Empty action, which will create service instance nodes (if needed) with no configuration steps" }
      end
      rest_ok_response response, response_opts
    end

    def rest__task_action_list
      assembly = ret_assembly_instance_object()
      rest_ok_response assembly.get_task_templates(set_display_names: true)
    end

    def rest__cancel_task
      assembly = ret_assembly_instance_object()

      unless top_task_id = ret_request_params(:task_id)
        if running_task = most_recent_task_is_executing?(assembly)
          top_task_id = running_task.id()
        else
          fail ErrorUsage.new('No running tasks found')
        end
      end

      cancel_task(top_task_id)
      rest_ok_response task_id: top_task_id
    end

    def rest__list_modules
      ids = ret_request_params(:assemblies)
      assembly_templates = get_assemblies_from_ids(ids)
      components = Assembly::Template.list_modules(assembly_templates)

      rest_ok_response components
    end

    def rest__prepare_for_edit_module
      assembly = ret_assembly_instance_object()
      module_type = ret_non_null_request_params(:module_type)

      response =
        case module_type.to_sym
          when :component_module
            module_name = ret_non_null_request_params(:module_name)
            namespace, sha, version_branch = AssemblyModule::Component.get_namespace_and_locked_branch_sha?(assembly, module_name)
            unless namespace
              fail ErrorUsage.new("A component module with name '#{module_name}' does not exist")
            end
            component_module = create_obj(:module_name, ComponentModule, namespace)
            opts = {}
            opts.merge!(sha: sha) if sha
            if version_branch && !version_branch[:version].eql?('master')
              opts.merge!(version: version_branch[:version], checkout_branch: true)
            end
            AssemblyModule::Component.prepare_for_edit(assembly, component_module, opts)
          when :service_module
            modification_type = ret_non_null_request_params(:modification_type).to_sym
            opts = ret_params_hash(:task_action, :create, :base_task_action)

            # TODO: support
            if opts[:create]
              fail ErrorUsage.new('create-workflow is not yet supported')
            end

            AssemblyModule::Service.prepare_for_edit(assembly, modification_type, opts)
          else
            fail ErrorUsage.new("Illegal module_type #{module_type}")
        end

      rest_ok_response response
    end

    def rest__promote_module_updates
      assembly = ret_assembly_instance_object()
      module_type, module_name = ret_non_null_request_params(:module_type, :module_name)

      unless module_type.to_sym == :component_module
        fail Error.new('promote_module_changes only treats component_module type')
      end

      unless namespace = AssemblyModule::Component.get_namespace?(assembly, module_name)
        fail ErrorUsage.new("A component module with name '#{module_name}' does not exist")
      end

      component_module = create_obj(:module_name, ComponentModule, namespace)
      opts = ret_boolean_params_hash(:force)
      rest_ok_response AssemblyModule::Component.promote_module_updates(assembly, component_module, opts)
    end

    def rest__prepare_for_pull_from_base
      assembly = ret_assembly_instance_object()
      module_type, module_name = ret_non_null_request_params(:module_type, :module_name)

      unless module_type.to_sym == :component_module
        fail Error.new('promote_module_changes only treats component_module type')
      end

      unless namespace = AssemblyModule::Component.get_namespace?(assembly, module_name)
        fail ErrorUsage.new("A component module with name '#{module_name}' does not exist")
      end

      _ns, _lck_sha, version_branch = AssemblyModule::Component.get_namespace_and_locked_branch_sha?(assembly, module_name)
      base_version = nil
      if version_branch && !version_branch[:version].eql?('master')
        fail ErrorUsage.new("You are not allowed to pull changes for specific component module version!") if  version_branch[:frozen]
        base_version = version_branch[:version]
      end

      component_module = create_obj(:module_name, ComponentModule, namespace)
      branch_info = AssemblyModule::Component.create_module_for_service_instance__for_pull?(assembly, component_module, base_version: base_version)
      branch_info.merge!(assembly_name: assembly[:display_name])

      rest_ok_response branch_info
    end

    AboutEnum = {
      instance: [:nodes, :components, :tasks, :attributes, :modules],
      template: [:nodes, :components, :targets]
    }
    FilterProc = {
      attributes: lambda { |attr| not attr[:hidden] }
    }

    def rest__add_ad_hoc_attribute_links
      assembly = ret_assembly_instance_object()
      target_attr_term, source_attr_term = ret_non_null_request_params(:target_attribute_term, :source_attribute_term)
      update_meta = ret_request_params(:update_meta)
      opts = {}
      # update_meta == true is the default
      unless !update_meta.nil? && !update_meta
        opts.merge!(update_meta: true)
      end
      AttributeLink::AdHoc.create_adhoc_links(assembly, target_attr_term, source_attr_term, opts)
      rest_ok_response
    end

    def rest__delete_service_link
      port_link = ret_port_link()
      Assembly::Instance::ComponentLink.delete(port_link.id_handle())
      rest_ok_response
    end

    def rest__add_service_link
      assembly = ret_assembly_instance_object()
      input_cmp_idh = ret_component_id_handle(:input_component_id, assembly)
      output_cmp_idh = ret_component_id_handle(:output_component_id, assembly, allow_external_component: true)
      link_name = ret_request_params(:dependency_name)
      opts =  (link_name ? { link_name: link_name } : {})
      service_link_idh = assembly.add_component_link(input_cmp_idh.create_object, output_cmp_idh.create_object, opts)
      rest_ok_response service_link: service_link_idh.get_id()
    end

    def rest__list_service_links
      assembly = ret_assembly_instance_object()
      component_id = ret_component_id?(:component_id, assembly)
      context = (ret_request_params(:context) || :assembly).to_sym
      opts = { context: context }
      opts.merge!(filter: { input_component_id: component_id }) if component_id
      ret = assembly.list_component_links(opts)
      rest_ok_response ret
    end

    # TODO: deprecate below for above
    def rest__list_connections
      assembly = ret_assembly_instance_object()
      find_missing, find_possible = ret_request_params(:find_missing, :find_possible)
      ret =
        if find_possible
          assembly.list_possible_component_links
        elsif find_missing
          fail Error.new('Deprecated')
        else
          fail Error.new('Deprecated')
        end
      rest_ok_response ret
    end

    def rest__get_attributes
      filter = ret_request_params(:filter)
      filter &&= filter.to_sym
      assembly = ret_assembly_instance_object()
      rest_ok_response assembly.get_attributes_print_form(Opts.new(filter: filter))
    end

    def rest__list
      subtype = ret_assembly_subtype()
      result =
        if subtype == :instance
          opts = ret_params_hash(:filter, :detail_level, :include_namespaces)
          opts.merge!(remove_assembly_wide_node: true)
          Assembly::Instance.list(model_handle(), opts)
        else
          project = get_default_project()
          opts = { version_suffix: true }.merge(ret_params_hash(:filter, :detail_level))
          Assembly::Template.list(model_handle(), opts.merge(project_idh: project.id_handle()))
        end
      rest_ok_response result
    end

    def rest__list_with_workspace
      opts = ret_params_hash(:filter)
      rest_ok_response Assembly::Instance.list_with_workspace(model_handle(), opts)
    end

    def rest__print_includes
      assembly = ret_assembly_instance_object()
      rest_ok_response assembly.print_includes(), encode_into: :yaml
    end

    def rest__apply_attribute_settings
      assembly = ret_assembly_instance_object()
      settings_hash = ret_attribute_settings_hash()
      ServiceSetting::AttributeSettings.apply_using_settings_hash(assembly, settings_hash)
      rest_ok_response
    end

    ##
    # Sets or creates attributes
    # TODO: update what input can be
    # the body has an array each element of form
    # {:pattern => PAT, :value => VAL}
    # pat can be one of three forms
    # 1 - an id
    # 2 - a name of form ASSEM-LEVEL-ATTR or NODE/COMONENT/CMP-ATTR, or
    # 3 - a pattern (TODO: give syntax) that can pick out multiple vars
    # this returns same output as info about attributes, pruned for just new ones set
    # TODO: this is a minsnomer in that it can be used to just create attributes
    def rest__set_attributes
      assembly       = ret_assembly_instance_object()
      av_pairs       = ret_params_av_pairs()
      opts           = ret_params_hash(:format, :context, :create)
      create_options = ret_boolean_params_hash(:required, :dynamic)

      if semantic_data_type = ret_request_params(:datatype)
        unless Attribute::SemanticDatatype.isa?(semantic_data_type)
          fail ErrorUsage.new("The term (#{semantic_data_type}) is not a valid data type")
        end
        create_options.merge!(semantic_data_type: semantic_data_type)
      end

      unless create_options.empty?
        unless opts[:create]
          fail ErrorUsage.new("Options (#{create_options.values.join(',')}) can only be given if :create is true")
        end
        opts.merge!(attribute_properties: create_options)
      end

      # update_meta == true is the default
      update_meta = ret_request_params(:update_meta)
      opts.merge!(update_meta: true) unless !update_meta.nil? && !update_meta

      opts.merge!(node_attribute: true) if ret_request_params(:node_attribute)
      opts.merge!(component_attribute: true) if ret_request_params(:component_attribute)

      attr_ret = assembly.set_attributes(av_pairs, opts)
      response = (attr_ret.is_a?(Hash) && attr_ret.key?(:ambiguous)) ? attr_ret : nil

      rest_ok_response response
    end

    #### actions to update and create assembly templates
    def rest__promote_to_template
      assembly = ret_assembly_instance_object()

      unless (ret_request_params(:assembly_template_name) && ret_request_params(:service_module_name))
        assembly.update_object!(:version)
        # TODO: see how assembly[:version] can be set to nil and fix there
        unless assembly[:version].eql?('master') or assembly[:version].nil?
          fail ErrorUsage.new("You are not allow to push updates to service module versions!") 
        end
      end

      assembly_template_name, service_module_name, module_namespace = get_template_and_service_names_params(assembly, check_frozen_branches: true)

      if assembly_template_name.nil? || service_module_name.nil?
        fail ErrorUsage.new('SERVICE-NAME/ASSEMBLY-NAME cannot be determined and must be explicitly given')
      end

      project = get_default_project()
      opts = ret_symbol_params_hash(:mode)

      namespace = ret_request_params(:namespace) ||
        (ret_request_param_boolean(:use_module_namespace) ? module_namespace : Namespace.default_namespace_name)
      opts.merge!(namespace: namespace)

      if description = ret_request_params(:description)
        opts.merge!(description: description)
      end

      if local_clone_dir_exists = ret_request_params(:local_clone_dir_exists)
        opts.merge!(local_clone_dir_exists: local_clone_dir_exists)
      end

      # push-assembly-updates always updates master branch
      service_module = Assembly::Template.create_or_update_from_instance(project, assembly, service_module_name, assembly_template_name, opts.merge!(version: 'master'))
      rest_ok_response service_module.ret_clone_update_info()
    end
    #### end: actions to update and create assembly templates

    #### methods to modify the assembly instance
    def rest__add_node
      assembly = ret_assembly_instance_object()
      assembly_node_name = ret_non_null_request_params(:assembly_node_name)
      node_binding_rs = node_binding_ruleset?(:node_template_identifier)
      node = assembly.add_node(assembly_node_name, node_binding_rs)

      image = ret_request_params(:image)
      instance_size = ret_request_params(:instance_size)
      assembly.add_ec2_properties_and_set_attributes(get_default_project(), node, image, instance_size)

      rest_ok_response node
    end

    def rest__add_node_group
      assembly        = ret_assembly_instance_object()
      node_group_name = ret_non_null_request_params(:node_group_name)
      node_binding_rs = node_binding_ruleset?(:node_template_identifier)
      cardinality     = ret_non_null_request_params(:cardinality)
      node_group      = assembly.add_node_group(node_group_name, node_binding_rs, cardinality)

      image = ret_request_params(:image)
      instance_size = ret_request_params(:instance_size)
      assembly.add_ec2_properties_and_set_attributes(get_default_project(), node_group, image, instance_size)

      rest_ok_response node_group.id_handle
    end

    def rest__add_component
      assembly = ret_assembly_instance_object()
      cmp_name, namespace = ret_request_params(:component_template_id, :namespace)
      cmp_name, version = ret_component_name_and_version(cmp_name)
      assembly_idh = assembly.id_handle()

      aug_component_template = Component::Template.get_augmented_base_component_template(assembly, cmp_name, namespace, version: version)

      component_title = ret_component_title?(cmp_name)
      node_id         = ret_request_params(:node_id)
      opts            = Opts.new(ret_boolean_params_hash(:idempotent, :donot_update_workflow, :auto_complete_links))
      node_idh        = node_id.empty? ? nil : ret_node_id_handle(:node_id, assembly)

      new_component_idh = assembly.add_component_deprecated(node_idh, aug_component_template, component_title, opts.merge!(project: get_default_project()))
      rest_ok_response(component_id: new_component_idh.get_id())
    end

    def rest__add_assembly_template
      assembly = ret_assembly_instance_object()
      assembly_template = ret_assembly_template_object(:assembly_template_id)
      assembly.add_assembly_template(assembly_template)
      rest_ok_response
    end

    def rest__stage
      opts = Opts.new

      is_silent_fail = ret_request_param_boolean(:silent_fail) || false
      is_created = true

      service_module_id = nil
      version = nil

      unless service_module_id = ret_request_params(:service_module_id)
        if ret_request_params(:service_module_name)
          service_module_id = create_obj(:service_module_name, ServiceModule).id
        end
      end

      # Special case to support Jenikins CLI orders, since we are not using shell we do not have access
      # to element IDs. This "workaround" helps with that.
      if service_module_id
        # this is name of assembly template
        assembly_id        = ret_request_params(:assembly_id)
        version            = ret_request_params(:version)
        service_module     = ServiceModule.find(model_handle(:service_module), service_module_id)

        raise ErrorUsage.new("Unable to find service module for specified parameters: '#{service_module_id}'") unless service_module

        # if we do not specify version use latest
        version = compute_latest_version(service_module) unless version
        
        module_name        = ret_request_params(:service_module_name)
        assembly_version   = (version.nil? || version.eql?('base')) ? 'master' : version
        assembly_templates = service_module.get_assembly_templates().select { |template| (template[:display_name].eql?(assembly_id) || template[:id] == assembly_id.to_i) }
        assembly_template  = assembly_templates.find{ |template| template[:version] == assembly_version }
        fail ErrorUsage, "We are not able to find assembly '#{assembly_id}' for service module '#{module_name}'" unless assembly_template
      else
        assembly_template = ret_assembly_template_object()
      end

      opts[:version] = version if version

      if service_settings = ret_settings_objects(assembly_template)
        opts[:service_settings] = service_settings
      end

      if node_size = ret_request_params(:node_size)
        opts[:node_size] = node_size
      end

      if os_type = ret_request_params(:os_type)
        opts[:os_type] = os_type
      end

      if no_auto_complete = ret_request_params(:no_auto_complete)
        opts[:no_auto_complete] = no_auto_complete
      end

      project = get_default_project()
      opts.merge!(project: project)

      if assembly_name = ret_request_params(:name)
        opts[:assembly_name] = assembly_name
      end

      target = nil
      target_assembly_instance =  nil
      if is_target_service = ret_request_params(:is_target)
        opts[:is_target_service] = true
        target_name = assembly_name || "#{service_module[:display_name]}-#{assembly_template[:display_name]}"
        target = Service::Target.create_target_mock(target_name, project)
        target_assembly_instance = ret_assembly_instance_object?(:parent_service)
      else
        # this case is for service instance which are staged against a target service instance
        # which is giving  parameter 'parent-service' or getting default target 
        target_service = ret_target_service_with_default(:parent_service)
        raise_error_if_target_not_convereged(target_service)
        target = target_service.target
        target_assembly_instance = target_service.assembly_instance
      end

      opts.merge!(parent_service_instance: target_assembly_instance) if target_assembly_instance

      begin
        new_assembly_obj = assembly_template.stage(target, opts)
      rescue DTK::ErrorUsage => e
        # delete mocked target service instance created above
        Target::Instance.delete_and_destroy(target) if is_target_service
        raise e unless is_silent_fail
        # in case we are using silent fail we wont response event if there was an error
        new_assembly_obj = Assembly::Instance.find_by_name?(target, opts[:assembly_name])
        is_created = false
        # in case there is still no assembly raise error
        raise e unless new_assembly_obj
      end

      if is_target_service
        display_name = new_assembly_obj.get_field?(:display_name)
        ref          = display_name.downcase.gsub(/ /, '-')
        target.update(display_name: display_name, ref: ref)
      end

      response = {
        new_service_instance: {
          name: new_assembly_obj.display_name_print_form,
          id: new_assembly_obj.id(),
          is_created: is_created
        }
      }

      if ret_request_params(:do_not_encode)
        rest_ok_response(response)
      else
        rest_ok_response(response, encode_into: :yaml)
      end
    end

    def rest__set_default_target
      service_instance = ret_assembly_instance_object()
      rest_ok_response service_instance.set_as_default_target
    end

    def rest__get_default_target
      target_service = ret_target_service_with_default()
      target_assembly_instance = target_service.assembly_instance
      rest_ok_response target_assembly_instance
    end

    def rest__create_workspace
      workspace_name = ret_request_params(:workspace_name)

      unless workspace_name
        instance_list = Assembly::Instance.list_with_workspace(model_handle())
        workspace_name = Workspace.calculate_workspace_name(instance_list)
      end

      # this case is for service instance which are staged against a target service instance
      # which is giving  parameter 'parent-service' or getting default target 
      target_service = ret_target_service_with_default(:parent_service)
      raise_error_if_target_not_convereged(target_service)
      target = target_service.target
      target_assembly_instance = target_service.assembly_instance

      opts = Opts.new()
      opts.merge!(parent_service_instance: target_assembly_instance) if target_assembly_instance
      opts.merge!(project: get_default_project())

      # TODO: eventually move Workspace.create to take a target_service, rather than target as an argument
      workspace = Workspace.create?(target.id_handle, get_default_project.id_handle, workspace_name, opts)

      response = {
        new_workspace_instance: {
          name: workspace[:display_name],
          id: workspace[:guid]
        }
      }

      if ret_request_params(:do_not_encode)
        rest_ok_response(response)
      else
        rest_ok_response(response, encode_into: :yaml)
      end
    end

    def rest__deploy
      # stage assembly template
      target_id = ret_request_param_id_optional(:target_id, Target::Instance)
      target = target_with_default(target_id)

      # Special case to support Jenikins CLI orders, since we are not using shell we do not have access
      # to element IDs. This "workaround" helps with that.
      if service_module_id = ret_request_params(:service_module_id)
        # this is name of assembly template
        assembly_id = ret_request_params(:assembly_id)
        service_module = ServiceModule.find(model_handle(:service_module), service_module_id)
        assembly_template = service_module.get_assembly_templates().find { |template| template[:display_name].eql?(assembly_id) || template[:id] == assembly_id.to_i }
        fail ErrorUsage, "We are not able to find assembly '#{assembly_id}' for service module '#{service_module_id}'" unless assembly_template
      else
        assembly_template = ret_assembly_template_object()
      end

      opts = {}
      if assembly_name = ret_request_params(:name)
        opts[:assembly_name] = assembly_name
      end
      if service_settings = ret_settings_objects(assembly_template)
        opts[:service_settings] = service_settings
      end
      assembly_instance = assembly_template.stage(target, opts)

      # create task
      unless task = Task.create_from_assembly_instance?(assembly_instance, ret_params_hash(:commit_msg))
        fail Error.new("There are no steps in the workflow to execute")
      end
      # saves to db and returns task with top level and sub task ids filled out
      task = task.save_and_add_ids()

      # execute task
      workflow = Workflow.create(task)
      workflow.defer_execution()

      response = {
        assembly_instance_id: assembly_instance.id(),
        assembly_instance_name: assembly_instance.display_name_print_form,
        task_id: task.id()
      }
      rest_ok_response response
    end

    def rest__list_settings
      assembly_template = ret_assembly_template_object()
      rest_ok_response assembly_template.get_settings()
    end

    #### end: method(s) related to staging assembly template

    def rest__find_violations
      assembly = ret_assembly_instance_object
      opts     = ret_boolean_params_hash(:ret_objects)

      violations = assembly.find_violations
      response = opts[:ret_objects] ? violations.hash_form : violations.table_form
      rest_ok_response response
    end

    def rest__ad_hoc_action_list
      assembly = ret_assembly_instance_object()
      type     = (ret_request_params(:type) || :component_type).to_sym
      datatype =
        case type
          when :component_type     then :ad_hoc_action_by_component_type
          when :component_instance then :ad_hoc_action_by_component_instance
          else fail ErrorUsage.new("Illegal type (#{type})")
        end

      response = Task::Template::Action::AdHoc.list(assembly, type)
      rest_ok_response response, datatype: datatype
    end

    def rest__ad_hoc_action_execute
      assembly = ret_assembly_instance_object()
      component = ret_component_instance(:component_id, assembly)
      opts = ret_params_hash(:method_name, :action_params)

      # create task, raising user error if task wide preconditions dont hold,
      # which in this case is mking sure all nodes in task are up
      task = Task.create_for_ad_hoc_action(assembly, component, opts)
      # saves to db and returns task with top level and sub task ids filled out
      task = task.save_and_add_ids()

      # execute task
      workflow = Workflow.create(task)
      workflow.defer_execution()

      response = {
        assembly_instance_id: assembly.id(),
        assembly_instance_name: assembly.display_name_print_form,
        task_id: task.id()
      }
      rest_ok_response response
    end

    def rest__exec
      assembly    = ret_assembly_instance_object()
      params_hash = ret_params_hash(:commit_msg, :task_action, :task_params, :start_assembly, :skip_violations, :noop_if_no_action)

      params_hash[:task_params] = params_hash[:task_params].is_a?(String) ? Hash.new : params_hash[:task_params]
      rest_ok_response assembly.exec(params_hash)
    end

    def rest__list_actions
      assembly = ret_assembly_instance_object()
      type     = ret_request_params(:type)
      rest_ok_response assembly.list_actions(type)
    end

    def rest__create_task
      assembly = ret_assembly_instance_object()
      opts     = ret_params_hash(:commit_msg, :task_action, :task_params)

      # TODO: more expensive, but more rebost to check for operationally stopped as opposed to
      #       just administratively stopped nodes (that is, use assembly.any_stopped_nodes?(:op))
      if assembly.any_stopped_nodes?(:admin)
        if ret_request_params(:start_assembly).nil?
          return rest_ok_response confirmation_message: true
        end

        opts.merge!(start_nodes: true, ret_nodes_to_start: [])
      else
        unless R8::Config[:debug][:disable_task_concurrent_check]
          if running_task = most_recent_task_is_executing?(assembly)
            fail ErrorUsage, "Task with id '#{running_task.id}' is already running in assembly. Please wait until task is complete or cancel task."
          end
        end
      end

      unless task = Task.create_from_assembly_instance?(assembly, opts)
        message = { message: "There are no steps in the workflow to execute" }
        return rest_ok_response(message)
      end
      task.save!()

      # update assembly_wide_node admin_op_status to 'running' on converge
      if assembly_wide_node = assembly.has_assembly_wide_node?
        assembly_wide_node.update_admin_op_status!(:running)
      end

      # TODO: clean up this part since this is doing more than creating task
      # This triggres start while in task have particpants that look for completion
      unless (opts[:ret_nodes_to_start]||[]).empty?
        Node.start_instances(opts[:ret_nodes_to_start])
      end

      rest_ok_response task_id: task.id
    end

    def rest__clear_tasks
      assembly = ret_assembly_instance_object()
      assembly.clear_tasks()
      rest_ok_response
    end

    def rest__start
      assembly     = ret_assembly_instance_object()
      node_pattern = ret_request_params(:node_pattern)
      task         = nil

      # filters only stopped nodes for this assembly
      nodes, is_valid, error_msg = assembly.nodes_valid_for_stop_or_start(node_pattern, :stopped)

      unless is_valid
        Log.info(error_msg)
        return rest_ok_response(errors: [error_msg])
      end

      opts = {}
      if (nodes.size == 1)
        opts.merge!(node: nodes.first)
      else
        opts.merge!(nodes: nodes)
      end

      task = Task.task_when_nodes_ready_from_assembly(assembly, :assembly, opts)
      task.save!()

      Node.start_instances(nodes)

      rest_ok_response task_id: task.id
    end

    def rest__stop
      assembly = ret_assembly_instance_object()
      node_pattern = ret_request_params(:node_pattern)

      # cancel task if running on the assembly
      if running_task = most_recent_task_is_executing?(assembly)
        cancel_task(running_task.id)
      end

      nodes, is_valid, error_msg = assembly.nodes_valid_for_stop_or_start(node_pattern, :running)

      unless is_valid
        Log.info(error_msg)
        return rest_ok_response(errors: [error_msg])
      end

      Node.stop_instances(nodes)
      rest_ok_response
    end

    def rest__stop_using_workflow
      assembly = ret_assembly_instance_object()
      node_pattern = ret_request_params(:node_pattern)

      # cancel task if running on the assembly
      if running_task = most_recent_task_is_executing?(assembly)
        cancel_task(running_task.id)
      end

      nodes, is_valid, error_msg = assembly.nodes_valid_for_stop_or_start(node_pattern, :running)

      unless is_valid
        Log.info(error_msg)
        return rest_ok_response(errors: [error_msg])
      end

      task = Task.create_top_level(assembly.model_handle(:task), assembly, task_action: 'stop nodes', temporal_order: 'concurrent')
      ret = {
        assembly_instance_id: assembly.id(),
        assembly_instance_name: assembly.display_name_print_form
      }

      nodes.each do |node|
        command_and_control_action = Task.create_for_command_and_control_action(assembly, 'stop_instances', node.id(), node, { task_action: 'stop node' })
        task.add_subtask(command_and_control_action) if command_and_control_action
      end
      task = task.save_and_add_ids()

      workflow = Workflow.create(task)
      workflow.defer_execution()

      ret.merge!(task_id: task.id())
      ret

      # Node.stop_instances(nodes)
      rest_ok_response ret
    end

    def rest__task_status
      begin
        assembly = ret_assembly_instance_object()
      rescue ErrorIdInvalid => e
        # if invalid id but sent from client it means this service instance is deleted few moments ago
        if ret_request_params(:assembly_id)
          return rest_ok_response [change_context: true]
        else
          raise e
        end
      end
      response =
        if ret_request_params(:form) == 'stream_form'
          element_detail = ret_request_params(:element_detail)||{}
          # element_detail defaults
          element_detail[:action_results] ||= true
          element_detail[:errors] ||= true
          opts = {
            end_index:      ret_request_params(:end_index),
            start_index:    ret_request_params(:start_index),
            element_detail: element_detail
          }
          if wait_for = ret_request_params(:wait_for)
            opts.merge!(wait_for: wait_for.to_sym)
          end

          Task::Status::Assembly::StreamForm.get_status(assembly.id_handle, opts)
        else
          opts = {
            format: (ret_request_params(:format) || :table).to_sym,
            detail_level: ret_boolean_params_hash(:summarize_node_groups)
          }
          Task::Status::Assembly.get_status(assembly.id_handle, opts)
        end

      rest_ok_response response
    end

    def rest__task_action_detail
      assembly = ret_assembly_instance_object()
      action_label = ret_request_params(:message_id)
      rest_ok_response Task::ActionResults.get_action_detail(assembly, action_label)
    end

    ### command and control actions
    def rest__initiate_get_log
      assembly = ret_assembly_instance_object()
      params = ret_params_hash(:log_path, :start_line)
      node_pattern = ret_params_hash(:node_identifier)

      nodes = ret_matching_nodes(assembly, node_pattern)
      nodes, is_valid, error_msg = assembly.nodes_are_up?(nodes, :running, what: 'Tail')

      unless is_valid
        Log.info(error_msg)
        return rest_ok_response(errors: error_msg)
      end

      queue = initiate_action(GetLog, assembly, params, node_pattern)
      rest_ok_response action_results_id: queue.id
    end

    def rest__initiate_grep
      assembly = ret_assembly_instance_object()
      params = ret_params_hash(:log_path, :grep_pattern, :stop_on_first_match)
      # TODO: should use in rest call :node_identifier
      np = ret_request_params(:node_pattern)
      node_pattern = (np ? { node_identifier: np } : {})

      nodes = ret_matching_nodes(assembly, node_pattern)
      nodes, is_valid, error_msg = assembly.nodes_are_up?(nodes, :running, what: 'Grep')

      unless is_valid
        Log.info(error_msg)
        return rest_ok_response(errors: error_msg)
      end

      queue = initiate_action(Grep, assembly, params, node_pattern)
      rest_ok_response action_results_id: queue.id
    end

    def rest__initiate_get_netstats
      assembly     = ret_assembly_instance_object()
      params       = {}
      node_pattern = ret_params_hash(:node_id)

      nodes = ret_matching_nodes(assembly, node_pattern)
      nodes, is_valid, error_msg = assembly.nodes_are_up?(nodes, :running, what: 'Get netstats')

      unless is_valid
        Log.info(error_msg)
        return rest_ok_response(errors: error_msg)
      end

      queue = initiate_action(GetNetstats, assembly, params, node_pattern)
      rest_ok_response action_results_id: queue.id
    end

    def rest__initiate_get_ps
      assembly = ret_assembly_instance_object()
      params = {}
      node_pattern = ret_params_hash(:node_id)

      nodes = ret_matching_nodes(assembly, node_pattern)
      nodes, is_valid, error_msg = assembly.nodes_are_up?(nodes, :running, { what: 'Get ps' })

      unless is_valid
        Log.info(error_msg)
        return rest_ok_response(errors: error_msg)
      end

      queue = initiate_action(GetPs, assembly, params, node_pattern)
      rest_ok_response action_results_id: queue.id
    end

    def rest__initiate_ssh_pub_access
      assembly = ret_assembly_instance_object()
      params   = ret_params_hash(:rsa_pub_name, :rsa_pub_key, :system_user)
      agent_action = ret_non_null_request_params(:agent_action).to_sym
      target_nodes = ret_matching_nodes(assembly)

      # stop if service staged
      fail ErrorUsage.new('Nodes are not running, has service been started?') unless assembly.node_admin_status_all_running?(target_nodes)

      # check existance of key and system user in database
      system_user = params[:system_user]
      key_name = params[:rsa_pub_name]
      nodes = Component::Instance::Interpreted.find_candidates(assembly, system_user, key_name, agent_action, target_nodes)

      queue = initiate_action_with_nodes(SSHAccess, nodes, params.merge(agent_action: agent_action)) do
        # need to put sanity checking in block under initiate_action_with_nodes
        if target_nodes_option = ret_request_params(:target_nodes)
          unless target_nodes_option.empty?
            fail ErrorUsage.new('Not implemented when target nodes option given')
          end
        end

        if agent_action == :revoke_access && nodes.empty?
          fail ErrorUsage.new("Access #{target_nodes.empty? ? '' : 'on given nodes'} is not granted to system user '#{system_user}' with name '#{key_name}'")
        end
        if agent_action == :grant_access && nodes.empty?
          fail ErrorUsage.new("Nodes already have access to system user '#{system_user}' with name '#{key_name}'")
        end
      end
      rest_ok_response action_results_id: queue.id
    end

    def rest__list_ssh_access
      assembly = ret_assembly_instance_object()
      rest_ok_response Component::Instance::Interpreted.list_ssh_access(assembly)
    end

    def rest__initiate_execute_tests
      node_id = ret_request_params(:node_id)
      component = ret_non_null_request_params(:components)
      assembly = ret_assembly_instance_object()
      project = get_default_project()

      # Filter only running nodes for this assembly
      nodes = assembly.get_leaf_nodes(cols: [:id, :display_name, :type, :external_ref, :hostname_external_ref, :admin_op_status])
      nodes, is_valid, error_msg = assembly.nodes_are_up?(nodes, :running, what: 'Serverspec tests')

      unless is_valid
        Log.info(error_msg)
        return rest_ok_response(errors: error_msg)
      end

      # Filter node if execute tests is started from the specific node
      nodes.select! { |node| node[:id] == node_id.to_i } unless node_id.nil?
      if nodes.empty?
        return rest_ok_response(errors: 'Unable to execute tests. Provided node is not valid!')
      end

      params = { nodes: nodes, component: component, agent_action: :execute_tests, project: project, assembly_instance: assembly }
      queue = initiate_execute_tests(ExecuteTests, params)
      return rest_ok_response(errors: queue.error) if queue.error
      rest_ok_response action_results_id: queue.id
    end

    def rest__get_action_results
      action_results_id = ret_non_null_request_params(:action_results_id)
      ret_only_if_complete = ret_request_param_boolean(:return_only_if_complete)
      disable_post_processing = ret_request_param_boolean(:disable_post_processing)
      sort_key = ret_request_params(:sort_key)

      if ret_request_param_boolean(:using_simple_queue)
        rest_ok_response SimpleActionQueue.get_results(action_results_id)
      else
        if sort_key
          sort_key = sort_key.to_sym
          rest_ok_response ActionResultsQueue.get_results(action_results_id, ret_only_if_complete, disable_post_processing, sort_key)
        else
          rest_ok_response ActionResultsQueue.get_results(action_results_id, ret_only_if_complete, disable_post_processing)
        end
      end
    end

    private

    def get_assemblies_from_ids(ids)
      assemblies = []
      ids.each do |id|
        assembly = id_handle(id.to_i, :component).create_object(model_name: :assembly_template)
        assemblies << assembly
      end

      assemblies
    end
  end
end
