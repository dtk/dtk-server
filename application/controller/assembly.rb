module DTK
  class AssemblyController < AuthController
    helper :assembly_helper
    helper :task_helper

    include Assembly::Instance::Action

    #### create and delete actions ###
    # TODO: rename to delete_and_destroy
    def rest__delete()
      assembly_id,subtype = ret_assembly_params_id_and_subtype()
      if subtype == :template
        # returning module_repo_info so client can update this in its local module
        rest_ok_response Assembly::Template.delete_and_ret_module_repo_info(id_handle(assembly_id))
      else #subtype == :instance
        Assembly::Instance.delete(id_handle(assembly_id),:destroy_nodes => true)
        rest_ok_response
      end
    end

    def rest__purge()
      workspace = ret_workspace_object?()
      workspace.purge(:destroy_nodes => true)
      rest_ok_response
    end

    def rest__destroy_and_reset_nodes()
      assembly = ret_assembly_instance_object()
      assembly.destroy_and_reset_nodes()
      rest_ok_response
    end

    def rest__remove_from_system()
      assembly = ret_assembly_instance_object()
      Assembly::Instance.delete(assembly.id_handle())
      rest_ok_response
    end

    def rest__set_target()
      workspace = ret_workspace_object?()
      target = create_obj(:target_id, Target::Instance)
      workspace.set_target(target)
      rest_ok_response
    end

    def rest__delete_node()
      assembly = ret_assembly_instance_object()
      # node_idh = ret_node_id_handle(:node_id,assembly)

      node_id = ret_non_null_request_params(:node_id)
      node_idh = ret_node_or_group_member_id_handle(node_id,assembly)

      assembly.delete_node(node_idh,:destroy_nodes => true)
      rest_ok_response
    end

    def rest__delete_component()
      # Retrieving node_id to validate if component belongs to node when delete-component invoked from component-level context
      node_id = ret_non_null_request_params(:node_id)
      component_id = ret_non_null_request_params(:component_id)
      assembly = ret_assembly_instance_object()
      assembly_id = assembly.id()
      cmp_full_name = ret_request_params(:cmp_full_name)

      # cmp_name, namespace = ret_non_null_request_params(:component_id, :namespace)
      cmp_name, namespace = ret_request_params(:component_id, :namespace)

      assembly_idh = assembly.id_handle()
      cmp_mh = assembly_idh.createMH(:component)

      if cmp_full_name
        # cmp_idh = ret_component_id_handle(:cmp_full_name,:assembly_id => assembly_id)
        component = Component.ret_component_with_namespace_for_node(cmp_mh, cmp_name, node_id, namespace, assembly)
        raise ErrorUsage.new("Component with identifier (#{namespace.nil? ? '' : namespace + ':'}#{cmp_name}) does not exist!") unless component

        cmp_idh = component.id_handle()
      else
        cmp_idh = id_handle(component_id,:component)
      end

      assembly.delete_component(cmp_idh, node_id)
      rest_ok_response
    end

    #### end: create and delete actions ###
    #### list and info actions ###
    def rest__info()
      assembly = ret_assembly_object()
      node_id, component_id, attribute_id, return_json, only_node_group_info = ret_request_params(:node_id, :component_id, :attribute_id, :json_return, :only_node_group_info)

      opts = {:only_node_group_info => true} if only_node_group_info
      if return_json.eql?('true')
        rest_ok_response assembly.info(node_id, component_id, attribute_id, opts||{})
      else
        rest_ok_response assembly.info(node_id, component_id, attribute_id, opts||{}), :encode_into => :yaml
      end
    end

    def rest__list_component_module_diffs()
      module_id, workspace_branch, module_branch_id, repo_id = ret_request_params(:module_id, :workspace_branch, :module_branch_id, :repo_id)
      repo          = id_handle(repo_id,:repo).create_object()
      project       = get_default_project()
      module_branch = id_handle(module_branch_id, :module_branch).create_object()

      project_idh = project.id_handle()
      opts = Opts.new(:project_idh => project_idh)

      rest_ok_response AssemblyModule::Component.list_remote_diffs(model_handle(), module_id, repo, module_branch, workspace_branch, opts)
    end

    def rest__get_component_modules()
      assembly = ret_assembly_object()
      rest_ok_response assembly.get_component_modules({:get_version_info=>true})
    end

    def rest__rename()
      assembly = ret_assembly_object()
      assembly_name = ret_non_null_request_params(:assembly_name)
      new_assembly_name = ret_non_null_request_params(:new_assembly_name)

      rest_ok_response assembly.rename(model_handle(), assembly_name, new_assembly_name)
    end

    # TODO: may be cleaner if we break into list_nodes, list_components with some shared helper functions
    def rest__info_about()
      node_id, component_id, detail_level, detail_to_include = ret_request_params(:node_id, :component_id, :detail_level, :detail_to_include)
      node_id = nil if node_id.kind_of?(String) and node_id.empty?
      component_id = nil if component_id.kind_of?(String) and component_id.empty?
      assembly,subtype = ret_assembly_params_object_and_subtype()
      response_opts = Hash.new
      if format = ret_request_params(:format)
        format = format.to_sym
        unless SupportedFormats.include?(format)
          raise ErrorUsage.new("Illegal format (#{format}) specified; it must be one of: #{SupportedFormats.join(',')}")
        end
      end

      about = ret_non_null_request_params(:about).to_sym
      unless AboutEnum[subtype].include?(about)
        raise ErrorUsage::BadParamValue.new(:about,AboutEnum[subtype])
      end

      opts = Opts.new(:detail_level => detail_level)
      additional_filter_proc = nil
      if about == :attributes
        if format == :yaml
          opts.merge!(:settings_form => true,:mark_unset_required => true)
        else
          opts.merge!(:truncate_attribute_values => true,:mark_unset_required => true)
        end

        additional_filter_opts = {
          :tags => ret_request_params(:tags),
          :editable => 'editable' == ret_request_params(:attribute_type)
        }
        additional_filter_proc = Proc.new do |e|
          attr = e[:attribute]
          (!attr.kind_of?(Attribute)) or !attr.filter_when_listing?(additional_filter_opts)
        end
      elsif about == :components
        # if not at node level filter out components on node group members (target_refs)
        unless node_id
          additional_filter_proc = Proc.new do |e|
            node = e[:node]
            (!node.kind_of?(Node)) or !Node::TargetRef.is_target_ref?(node)
          end
        end
      end

      opts[:filter_proc] = Proc.new do |e|
        if element_matches?(e,[:node,:id],node_id) and
            element_matches?(e,[:attribute,:component_component_id],component_id)
          if additional_filter_proc.nil? or additional_filter_proc.call(e)
            e
          end
        end
      end
      opts.add_return_datatype!()
      if detail_to_include
        opts.merge!(:detail_to_include => detail_to_include.map{|r|r.to_sym})
        opts.add_value_to_return!(:datatype)
      end

      if node_id
        opts.merge!(:node_cmp_name => true)
      end

      data = assembly.info_about(about, opts)
      datatype = opts.get_datatype
      response_opts = Hash.new
      if format == :yaml
        response_opts.merge!(:encode_into => :yaml)
      else
        response_opts.merge!(:datatype => datatype)
      end
      rest_ok_response data, response_opts
    end
    SupportedFormats = [:yaml]

    def rest__info_about_task()
      assembly = ret_assembly_instance_object()
      task_action = ret_request_params(:task_action)
      response = assembly.get_task_template_serialized_content(task_action)
      response_opts = Hash.new
      if response
        response_opts.merge!(:encode_into => :yaml)
      else
        response = {:message => "Task not yet generated for assembly (#{assembly.get_field?(:display_name)})"}
      end
      rest_ok_response response, response_opts
    end

    def rest__cancel_task()
      assembly = ret_assembly_instance_object()
      unless top_task_id = ret_request_params(:task_id)
        unless top_task = get_most_recent_executing_task([:eq,:assembly_id,assembly.id()])
          raise ErrorUsage.new("No running tasks found")
        end
        top_task_id = top_task.id()
      end
      cancel_task(top_task_id)
      rest_ok_response :task_id => top_task_id
    end

    def rest__list_modules()
      ids = ret_request_params(:assemblies)
      assembly_templates = get_assemblies_from_ids(ids)
      components = Assembly::Template.list_modules(assembly_templates)

      rest_ok_response components
    end

    def rest__prepare_for_edit_module()
      assembly = ret_assembly_instance_object()
      module_type = ret_non_null_request_params(:module_type)

      response =
        case module_type.to_sym
          when :component_module
            module_name = ret_non_null_request_params(:module_name)
            namespace = AssemblyModule::Component.validate_component_module_ret_namespace(assembly,module_name)
            component_module = create_obj(:module_name,ComponentModule,namespace)
            AssemblyModule::Component.prepare_for_edit(assembly,component_module)
          when :service_module
            modification_type = ret_non_null_request_params(:modification_type).to_sym
            AssemblyModule::Service.prepare_for_edit(assembly,modification_type)
          else
            raise ErrorUsage.new("Illegal module_type #{module_type}")
        end

      rest_ok_response response
    end

    def rest__promote_module_updates()
      assembly = ret_assembly_instance_object()
      module_type, module_name = ret_non_null_request_params(:module_type,:module_name)

      unless module_type.to_sym == :component_module
        raise Error.new("promote_module_changes only treats component_module type")
      end

      namespace = AssemblyModule::Component.validate_component_module_ret_namespace(assembly,module_name)
      component_module = create_obj(:module_name,ComponentModule,namespace)
      opts = ret_boolean_params_hash(:force)
      rest_ok_response AssemblyModule::Component.promote_module_updates(assembly,component_module,opts)
    end

    def rest__create_component_dependency()
      assembly = ret_assembly_instance_object()
      cmp_template = ret_component_template(:component_template_id)
      antecedent_cmp_template = ret_component_template(:antecedent_component_template_id)
      type = :simple
      AssemblyModule::Component.create_component_dependency?(type,assembly,cmp_template,antecedent_cmp_template)
      rest_ok_response
    end

    AboutEnum = {
      :instance => [:nodes,:components,:tasks,:attributes,:modules],
      :template => [:nodes,:components,:targets]
    }
    FilterProc = {
      :attributes => lambda{|attr|not attr[:hidden]}
    }

    def rest__add_ad_hoc_attribute_links()
      assembly = ret_assembly_instance_object()
      target_attr_term,source_attr_term = ret_non_null_request_params(:target_attribute_term,:source_attribute_term)
      update_meta = ret_request_params(:update_meta)
      opts = Hash.new
      # update_meta == true is the default
      unless !update_meta.nil? and !update_meta
        opts.merge!(:update_meta => true)
      end
      AttributeLink::AdHoc.create_adhoc_links(assembly,target_attr_term,source_attr_term,opts)
      rest_ok_response
    end

    def rest__delete_service_link()
      port_link = ret_port_link()
      Assembly::Instance::ServiceLink.delete(port_link.id_handle())
      rest_ok_response
    end

    def rest__add_service_link()
      assembly = ret_assembly_instance_object()
      assembly_id = assembly.id()
      input_cmp_idh = ret_component_id_handle(:input_component_id,:assembly_id => assembly_id)
      output_cmp_idh = ret_component_id_handle(:output_component_id,:assembly_id => assembly_id)
      opts = ret_params_hash(:dependency_name)
      service_link_idh = assembly.add_service_link?(input_cmp_idh,output_cmp_idh,opts)
      rest_ok_response :service_link => service_link_idh.get_id()
    end

    def rest__list_attribute_mappings()
      port_link = ret_port_link()
      # TODO: stub
      ams = port_link.list_attribute_mappings()
      pp ams
      rest_ok_response
    end

    def rest__list_service_links()
      assembly = ret_assembly_instance_object()
      component_id = ret_component_id?(:component_id,:assembly_id => assembly.id())
      context = (ret_request_params(:context)||:assembly).to_sym
      opts = {:context => context}
      if component_id
        opts.merge!(:filter => {:input_component_id => component_id})
      end
      ret = assembly.list_service_links(opts)
      rest_ok_response ret
    end
    # TODO: deprecate below for above
    def rest__list_connections()
      assembly = ret_assembly_instance_object()
      find_missing,find_possible = ret_request_params(:find_missing,:find_possible)
      ret =
        if find_possible
          assembly.list_connections__possible()
        elsif find_missing
          raise Error.new("Deprecated")
        else
          raise Error.new("Deprecated")
        end
      rest_ok_response ret
    end

    def rest__list_possible_add_ons()
      assembly = ret_assembly_instance_object()
      rest_ok_response assembly.get_service_add_ons()
    end

    def rest__get_attributes()
      filter = ret_request_params(:filter)
      filter = filter && filter.to_sym
      assembly = ret_assembly_instance_object()
      rest_ok_response assembly.get_attributes_print_form(Opts.new(:filter => filter))
    end


    def rest__workspace_object()
      rest_ok_response Assembly::Instance.get_workspace_object(model_handle(),{})
    end

    def rest__list()
      subtype = ret_assembly_subtype()
      result =
        if subtype == :instance
          opts = ret_params_hash(:filter,:detail_level,:include_namespaces)
          Assembly::Instance.list(model_handle(),opts)
        else
          project = get_default_project()
          opts = {:version_suffix => true}.merge(ret_params_hash(:filter,:detail_level))
          Assembly::Template.list(model_handle(),opts.merge(:project_idh => project.id_handle()))
        end
      rest_ok_response result
    end

    def rest__list_with_workspace()
      opts = ret_params_hash(:filter)
      rest_ok_response Assembly::Instance.list_with_workspace(model_handle(),opts)
    end

    def rest__print_includes()
      assembly = ret_assembly_instance_object()
      rest_ok_response assembly.print_includes(), :encode_into => :yaml
    end

    #### end: list and info actions ###

    def rest__apply_attribute_settings()
      assembly = ret_assembly_instance_object()
      settings_hash = ret_attribute_settings_hash()
      ServiceSetting::AttributeSettings.apply_using_settings_hash(assembly,settings_hash)
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
    def rest__set_attributes()
      assembly = ret_assembly_instance_object()
      av_pairs = ret_params_av_pairs()
      opts = ret_params_hash(:format,:context,:create)
      create_options = ret_boolean_params_hash(:required,:dynamic)
      if semantic_data_type = ret_request_params(:datatype)
        unless Attribute::SemanticDatatype.isa?(semantic_data_type)
          raise ErrorUsage.new("The term (#{semantic_data_type}) is not a valid data type")
        end
        create_options.merge!(:semantic_data_type => semantic_data_type)
      end
      unless create_options.empty?
        unless opts[:create]
          raise ErrorUsage.new("Options (#{create_options.values.join(',')}) can only be given if :create is true")
        end
        opts.merge!(:attribute_properties => create_options)
      end
      # update_meta == true is the default
      update_meta = ret_request_params(:update_meta)
      unless !update_meta.nil? and !update_meta
        opts.merge!(:update_meta => true)
      end

      assembly.set_attributes(av_pairs,opts)
      rest_ok_response
    end

    #### actions to update and create assembly templates
    def rest__promote_to_template()
      assembly = ret_assembly_instance_object()
      assembly_template_name,service_module_name,module_namespace = get_template_and_service_names_params(assembly)

      if assembly_template_name.nil? or service_module_name.nil?
        raise ErrorUsage.new("SERVICE-NAME/ASSEMBLY-NAME cannot be determined and must be explicitly given")
      end
      project = get_default_project()
      opts = ret_symbol_params_hash(:mode)

      if namespace = ret_request_params(:namespace)
        opts.merge!(:namespace => namespace)
      elsif ret_request_params(:use_module_namespace)
        opts.merge!(:namespace => module_namespace)
      end

      if description = ret_request_params(:description)
        opts.merge!(:description => description)
      end

      if local_clone_dir_exists = ret_request_params(:local_clone_dir_exists)
        opts.merge!(:local_clone_dir_exists => local_clone_dir_exists)
      end

      service_module = Assembly::Template.create_or_update_from_instance(project,assembly,service_module_name,assembly_template_name,opts)
      rest_ok_response service_module.ret_clone_update_info()
    end
    #### end: actions to update and create assembly templates

    #### methods to modify the assembly instance
    def rest__add_node()
      assembly = ret_assembly_instance_object()
      assembly_node_name = ret_non_null_request_params(:assembly_node_name)
      node_binding_rs = node_binding_ruleset?(:node_template_identifier)
      node_instance_idh = assembly.add_node(assembly_node_name,node_binding_rs)

      rest_ok_response node_instance_idh
    end

    def rest__add_node_group()
      assembly        = ret_assembly_instance_object()
      node_group_name = ret_non_null_request_params(:node_group_name)
      node_binding_rs = node_binding_ruleset?(:node_template_identifier)
      cardinality     = ret_non_null_request_params(:cardinality)
      node_group_idh  = assembly.add_node_group(node_group_name, node_binding_rs, cardinality)

      rest_ok_response node_group_idh
    end

    def rest__add_component()
      assembly = ret_assembly_instance_object()
      cmp_name, namespace = ret_request_params(:component_template_id, :namespace)
      assembly_idh = assembly.id_handle()

      cmp_mh = assembly_idh.createMH(:component)
      unless aug_component_template = Component::Template.get_augmented_component_template(cmp_mh, cmp_name, namespace, assembly)
        raise ErrorUsage.new("Component with identifier #{namespace.nil? ? '\'' : ('\'' + namespace + ':')}#{cmp_name}' does not exist!")
      end
      component_title = ret_component_title?(cmp_name)
      # not checking here if node_id points to valid object; check is in add_component
      node_idh = ret_request_param_id_handle(:node_id,Node)
      new_component_idh = assembly.add_component(node_idh,aug_component_template,component_title)

      rest_ok_response(:component_id => new_component_idh.get_id())
    end

    def rest__add_assembly_template()
      assembly = ret_assembly_instance_object()
      assembly_template = ret_assembly_template_object(:assembly_template_id)
      assembly.add_assembly_template(assembly_template)
      rest_ok_response
    end

    def rest__add_service_add_on()
      assembly = ret_assembly_instance_object()
      add_on_name = ret_non_null_request_params(:service_add_on_name)
      new_sub_assembly_idh = assembly.service_add_on(add_on_name)
      rest_ok_response(:sub_assembly_id => new_sub_assembly_idh.get_id())
    end

    #### end: methods to modify the assembly instance

    #### method(s) related to staging assembly template
    def rest__stage()
      target_id = ret_request_param_id_optional(:target_id, Target::Instance)
      target = target_idh_with_default(target_id).create_object(:model_name => :target_instance)
      assembly_template = ret_assembly_template_object()
      opts = Hash.new
      if assembly_name = ret_request_params(:name)
        opts[:assembly_name] = assembly_name
      end
      if service_settings = ret_settings_objects(assembly_template)
        opts[:service_settings] = service_settings
      end
      new_assembly_obj = assembly_template.stage(target, opts)

      response = {
        :new_service_instance => {
          :name => new_assembly_obj.display_name_print_form,
          :id => new_assembly_obj.id()
        }
      }
      rest_ok_response(response,:encode_into => :yaml)
    end

    def rest__deploy()
      # stage assembly template
      target_id = ret_request_param_id_optional(:target_id, Target::Instance)
      target = target_idh_with_default(target_id).create_object(:model_name => :target_instance)
      assembly_template = ret_assembly_template_object()
      opts = Hash.new
      if assembly_name = ret_request_params(:name)
        opts[:assembly_name] = assembly_name
      end
      if service_settings = ret_settings_objects(assembly_template)
        opts[:service_settings] = service_settings
      end
      assembly_instance = assembly_template.stage(target, opts)

      # see if any violations
      violation_objects = assembly_instance.find_violations()
      unless violation_objects.empty?
        violation_table = violation_objects.map do |v|
          {:type => v.type(),:description => v.description()}
        end
        error_data = {
          :violations => violation_table.uniq
        }
        error_msg = "Assembly cannot be executed because of violations"
#        return rest_notok_response(:code => :assembly_violations, :message => error_msg, :data => error_data)
      end

      # create task
      task = Task.create_from_assembly_instance(assembly_instance,ret_params_hash(:commit_msg))
      task.save!()

      # TODO: this is simple but expensive way to get all teh embedded task ids filled out
      # can replace with targeted method that does just this
      task = Task.get_hierarchical_structure(task.id_handle())
      # execute task
      workflow = Workflow.create(task)
      workflow.defer_execution()

      response = {
        :assembly_instance_id => assembly_instance.id(),
        :assembly_instance_name => assembly_instance.display_name_print_form,
        :task_id => task.id()
      }
      rest_ok_response response
    end

    def rest__list_settings()
      assembly_template = ret_assembly_template_object()
      rest_ok_response assembly_template.get_settings()
    end

    #### end: method(s) related to staging assembly template

    #### creates tasks to execute/converge assemblies and monitor status
    def rest__find_violations()
      assembly = ret_assembly_instance_object()
      violation_objects = assembly.find_violations()

      violation_table = violation_objects.map do |v|
        {:type => v.type(),:description => v.description()}
      end.sort{|a,b|a[:type].to_s <=> b[:type].to_s}

      rest_ok_response violation_table.uniq
    end

    def rest__create_task()
      assembly = ret_assembly_instance_object()
      assembly_is_stopped = assembly.any_stopped_nodes?()

      if assembly_is_stopped and ret_request_params(:start_assembly).nil?
        return rest_ok_response :confirmation_message=>true
      end

      if assembly.are_nodes_running_in_task?()
        raise ErrorUsage, "Task is already running on requested nodes. Please wait until task is complete"
      end

      opts = ret_params_hash(:commit_msg)
      if assembly_is_stopped
        opts.merge!(:start_node_changes => true, :ret_nodes => Array.new)
      end
      task = Task.create_from_assembly_instance(assembly,opts)
      task.save!()

      # TODO: clean up this part since this is doing more than creating task
      nodes_to_start =  (opts[:ret_nodes]||[]).reject{|n|n[:admin_op_status] == "running"}
      unless nodes_to_start.empty?
        CreateThread.defer_with_session(CurrentSession.new.user_object(), Ramaze::Current::session) do
          # invoking command to start the nodes
          CommandAndControl.start_instances(nodes_to_start)
        end
      end

      rest_ok_response :task_id => task.id
    end

    def rest__clear_tasks()
      assembly = ret_assembly_instance_object()
      assembly.clear_tasks()
      rest_ok_response
    end

    #TODO: cleanup
    def rest__start()
      assembly     = ret_assembly_instance_object()
      node_pattern = ret_request_params(:node_pattern)
      task         = nil

      # filters only stopped nodes for this assembly
      nodes, is_valid, error_msg = assembly.nodes_valid_for_stop_or_start(node_pattern, :stopped)

      unless is_valid
        Log.info(error_msg)
        return rest_ok_response(:errors => [error_msg])
      end

      opts ={}
      if (nodes.size == 1)
        opts.merge!(:node => nodes.first)
      else
        opts.merge!(:nodes => nodes)
      end

      task = Task.task_when_nodes_ready_from_assembly(assembly,:assembly, opts)
      task.save!()

      # queue = SimpleActionQueue.new

      user_object  = CurrentSession.new.user_object()
      CreateThread.defer_with_session(user_object, Ramaze::Current::session) do
        # invoking command to start the nodes
        CommandAndControl.start_instances(nodes)
      end

      # queue.set_result(:task_id => task.id)
      rest_ok_response :task_id => task.id
    end

    def rest__stop()
      assembly = ret_assembly_instance_object()
      node_pattern = ret_request_params(:node_pattern)

      nodes, is_valid, error_msg = assembly.nodes_valid_for_stop_or_start(node_pattern, :running)

      unless is_valid
        Log.info(error_msg)
        return rest_ok_response(:errors => [error_msg])
      end

      Node.stop_instances(nodes)

      rest_ok_response :status => :ok
    end

    def rest__task_status()
      assembly = ret_assembly_instance_object()
      opts = {
        :format       => (ret_request_params(:format)||:hash).to_sym,
        :detail_level => ret_boolean_params_hash(:summarize_node_groups)
      }
      response = Task::Status::Assembly.get_status(assembly.id_handle,opts)
      rest_ok_response response
    end

    def rest__task_action_detail()
      assembly = ret_assembly_instance_object()
      action_label = ret_request_params(:message_id)
      rest_ok_response Task::ActionResults.get_action_detail(assembly, action_label)
    end

    ### command and control actions
    def rest__initiate_get_log()
      assembly = ret_assembly_instance_object()
      params = ret_params_hash(:log_path, :start_line)
      node_pattern = ret_params_hash(:node_identifier)

      nodes = ret_matching_nodes(assembly, node_pattern)
      nodes, is_valid, error_msg = assembly.nodes_are_up?(nodes, :running, {:what => "Tail"})

      unless is_valid
        Log.info(error_msg)
        return rest_ok_response(:errors => error_msg)
      end

      queue = initiate_action(GetLog, assembly, params, node_pattern)
      rest_ok_response :action_results_id => queue.id
    end

    def rest__initiate_grep()
      assembly = ret_assembly_instance_object()
      params = ret_params_hash(:log_path, :grep_pattern, :stop_on_first_match)
      #TODO: should use in rest call :node_identifier
      np = ret_request_params(:node_pattern)
      node_pattern = (np ? {:node_identifier => np} : {})

      nodes = ret_matching_nodes(assembly, node_pattern)
      nodes, is_valid, error_msg = assembly.nodes_are_up?(nodes, :running, {:what => "Grep"})

      unless is_valid
        Log.info(error_msg)
        return rest_ok_response(:errors => error_msg)
      end

      queue = initiate_action(Grep, assembly, params, node_pattern)
      rest_ok_response :action_results_id => queue.id
    end

    def rest__initiate_get_netstats()
      assembly = ret_assembly_instance_object()
      params = Hash.new
      node_pattern = ret_params_hash(:node_id)

      nodes = ret_matching_nodes(assembly, node_pattern)
      nodes, is_valid, error_msg = assembly.nodes_are_up?(nodes, :running, {:what => "Get netstats"})

      unless is_valid
        Log.info(error_msg)
        return rest_ok_response(:errors => error_msg)
      end

      queue = initiate_action(GetNetstats, assembly, params, node_pattern)
      rest_ok_response :action_results_id => queue.id
    end

    def initiate_action_agent()
      node   = create_obj(:node_id, ::DTK::Node)
      params = ret_params_hash(:bash_command)

      params.merge!(
        :action_agent_request => {
        :env_vars => { :HARIS => 'WORKS', :NESTO => 21 },
        :execution_list => [
          {
            :type    => 'syscall',
            #:command => "script -qfc 'JAVA_HOME=\"/usr/lib/jvm/java-1.7.0-openjdk-1.7.0.75.x86_64\" HADOOP_HOME=\"/usr/lib/hadoop\" HADOOP_CONF_DIR=\"/etc/hadoop/conf/\" /usr/local/maven/bin/mvn verify -f /etc/puppet/modules/action_module/dtk/bigtop_tests/bigtop-tests/test-execution/smokes/hadoop/pom.xml'",
            :command => "date",
            :if      => 'echo works!'
          },
          # {
          #   :type    => 'syscall',
          #   :command => 'more /root/thor/README.md'
          # }
          ],
        :positioning2 => [
        {
          :type => 'file',
          :source => {
            :type => 'git',
            :url => "https://github.com/erikhuda/thor.git",
            :ref => 'master'
          },
          :target => {
            :path => "/root/thor"
          },
        },
        {
          :type => 'file',
          :source => {
            :type => 'in_payload',
            :content => "Hello WORLD!"
          },
          :target => {
            :path => "/root/test-folder/site-stage-1-invocation-1.pp"
          }
        }]})

      queue  = initiate_action_with_nodes(ActionAgent, [node], params)
      rest_ok_response :action_results_id => queue.id
    end

    def rest__initiate_get_ps()
      assembly = ret_assembly_instance_object()
      params = Hash.new
      node_pattern = ret_params_hash(:node_id)

      nodes = ret_matching_nodes(assembly, node_pattern)
      nodes, is_valid, error_msg = assembly.nodes_are_up?(nodes, :running, {:what => "Get ps"})

      unless is_valid
        Log.info(error_msg)
        return rest_ok_response(:errors => error_msg)
      end

      queue = initiate_action(GetPs, assembly, params, node_pattern)
      rest_ok_response :action_results_id => queue.id
    end

    def rest__initiate_ssh_pub_access()
      assembly = ret_assembly_instance_object()
      params   = ret_params_hash(:rsa_pub_name, :rsa_pub_key, :system_user)
      agent_action = ret_non_null_request_params(:agent_action).to_sym
      target_nodes = ret_matching_nodes(assembly)

      # check existance of key and system user in database
      system_user, key_name = params[:system_user], params[:rsa_pub_name]
      nodes = Component::Instance::Interpreted.find_candidates(assembly, system_user, key_name, agent_action, target_nodes)

      queue = initiate_action_with_nodes(SSHAccess,nodes,params.merge(:agent_action => agent_action)) do
        # need to put sanity checking in block under initiate_action_with_nodes
        if target_nodes_option = ret_request_params(:target_nodes)
          unless target_nodes_option.empty?
            raise ErrorUsage.new("Not implemented when target nodes option given")
          end
        end

        if agent_action == :revoke_access && nodes.empty?
          raise ErrorUsage.new("Access #{target_nodes.empty? ? '' : 'on given nodes'} is not granted to system user '#{system_user}' with name '#{key_name}'")
        end
        if agent_action == :grant_access && nodes.empty?
          raise ErrorUsage.new("Nodes already have access to system user '#{system_user}' with name '#{key_name}'")
        end
      end
      rest_ok_response :action_results_id => queue.id
    end

    def rest__list_ssh_access()
      assembly = ret_assembly_instance_object()
      rest_ok_response Component::Instance::Interpreted.list_ssh_access(assembly)
    end

    def rest__initiate_execute_tests()
      node_id = ret_request_params(:node_id)
      component = ret_non_null_request_params(:components)
      assembly = ret_assembly_instance_object()
      project = get_default_project()

      # Filter only running nodes for this assembly
      nodes = assembly.get_leaf_nodes(:cols => [:id,:display_name,:type,:external_ref,:hostname_external_ref, :admin_op_status])
      nodes, is_valid, error_msg = assembly.nodes_are_up?(nodes, :running, {:what => "Serverspec tests"})

      unless is_valid
        Log.info(error_msg)
        return rest_ok_response(:errors => error_msg)
      end

      # Filter node if execute tests is started from the specific node
      nodes.select! { |node| node[:id] == node_id.to_i } unless node_id.nil?
      if nodes.empty?
        return rest_ok_response(:errors => "Unable to execute tests. Provided node is not valid!")
      end

      params = {:nodes => nodes, :component => component, :agent_action => :execute_tests, :project => project, :assembly_instance => assembly}
      queue = initiate_execute_tests(ExecuteTests, params)
      return rest_ok_response(:errors => queue.error) if queue.error
      rest_ok_response :action_results_id => queue.id
    end

    def rest__get_action_results()
      # TODO: to be safe need to garbage collect on ActionResultsQueue in case miss anything
      action_results_id = ret_non_null_request_params(:action_results_id)
      ret_only_if_complete = ret_request_param_boolean(:return_only_if_complete)
      disable_post_processing = ret_request_param_boolean(:disable_post_processing)
      sort_key = ret_request_params(:sort_key)

      if ret_request_param_boolean(:using_simple_queue)
        rest_ok_response SimpleActionQueue.get_results(action_results_id)
      else
        if sort_key
          sort_key = sort_key.to_sym
          rest_ok_response ActionResultsQueue.get_results(action_results_id,ret_only_if_complete,disable_post_processing, sort_key)
        else
          rest_ok_response ActionResultsQueue.get_results(action_results_id,ret_only_if_complete,disable_post_processing)
        end
      end
    end
    ### end: mcollective actions

# TODO: got here in cleanup of rest calls

    def rest__list_smoketests()
      assembly = ret_assembly_object()
      rest_ok_response assembly.list_smoketests()
    end

    def test_get_items(id)
      assembly = id_handle(id,:component).create_object()
      item_list = assembly.get_items()

      return {
        :data=>item_list
      }
    end

    def search
      params = request.params.dup
      cols = model_class(:component).common_columns()

      filter_conjuncts = params.map do |name,value|
        [:regex,name.to_sym,"^#{value}"] if cols.include?(name.to_sym)
      end.compact

      # restrict results to belong to library and not nested in assembly
      filter_conjuncts += [[:eq,:type,"composite"],[:neq,:library_library_id,nil],[:eq,:assembly_id,nil]]
      sp_hash = {
        :cols => cols,
        :filter => [:and] + filter_conjuncts
      }
      component_list = Model.get_objs(model_handle(:component),sp_hash).each{|r|r.materialize!(cols)}

      i18n = get_i18n_mappings_for_models(:component)
      component_list.each_with_index do |model,index|
        component_list[index][:model_name] = :component
        component_list[index][:ui] ||= {}
        component_list[index][:ui][:images] ||= {}
#        name = component_list[index][:display_name]
        name = Assembly.pretty_print_name(component_list[index])
        title = name.nil? ? "" : i18n_string(i18n,:component,name)

# TODO: change after implementing all the new types and making generic icons for them
        model_type = 'service'
        model_sub_type = 'db'
        model_type_str = "#{model_type}-#{model_sub_type}"
        prefix = "#{R8::Config[:base_images_uri]}/v1/componentIcons"
        png = component_list[index][:ui][:images][:tnail] || "unknown-#{model_type_str}.png"
        component_list[index][:image_path] = "#{prefix}/#{png}"

        component_list[index][:i18n] = title
      end

      return {:data=>component_list}
    end

    def get_tree(id)
      return {:data=>'some tree data goes here'}
    end

    def get_assemblies_from_ids(ids)
      assemblies = []
      ids.each do |id|
        assembly = id_handle(id.to_i,:component).create_object(:model_name => :assembly_template)
        assemblies << assembly
      end

      return assemblies
    end

    # TODO: unify with clone(id)
    # clone assembly from library to target
    def stage()
      target_idh = target_idh_with_default(request.params["target_id"])
      assembly_id = ret_request_param_id(:assembly_id,::DTK::Assembly::Template)

      # TODO: if naem given and not unique either reject or generate a -n suffix
      assembly_name = ret_request_params(:name)

      id_handle = id_handle(assembly_id)

      # TODO: need to copy in avatar when hash["ui"] is non null
      override_attrs = Hash.new
      override_attrs[:display_name] = assembly_name if assembly_name

      target_object = target_idh.create_object()
      clone_opts = {:ret_new_obj_with_cols => [:id,:type]}
      new_assembly_obj = target_object.clone_into(id_handle.create_object(),override_attrs,clone_opts)
      id = new_assembly_obj && new_assembly_obj.id()

      # compute ui positions
      nested_objs = new_assembly_obj.get_node_assembly_nested_objects()
      # TODO: this does not leverage assembly node relative positions
      nested_objs[:nodes].each do |node|
        target_object.update_ui_for_new_item(node[:id])
      end
      rest_ok_response(:assembly_id => id)
    end

    # clone assembly from library to target
    def clone(id)
      handle_errors do
        id_handle = id_handle(id)
        hash = request.params
        target_id_handle = nil
        if hash["target_id"] and hash["target_model_name"]
          input_target_id_handle = id_handle(hash["target_id"].to_i,hash["target_model_name"].to_sym)
          target_id_handle = Model.find_real_target_id_handle(id_handle,input_target_id_handle)
        else
          Log.info("not implemented yet")
          return redirect "/xyz/#{model_name()}/display/#{id.to_s}"
        end

        # TODO: need to copy in avatar when hash["ui"] is non null
        override_attrs = hash["ui"] ? {:ui=>hash["ui"]} : {}
        target_object = target_id_handle.create_object()
        clone_opts = {:ret_new_obj_with_cols => [:id,:type]}
        new_assembly_obj = target_object.clone_into(id_handle.create_object(),override_attrs,clone_opts)
        id = new_assembly_obj && new_assembly_obj.id()
        nested_objs = new_assembly_obj.get_node_assembly_nested_objects()

        # just want external ports
        (nested_objs[:nodes]||[]).each{|n|(n[:ports]||[]).reject!{|p|p[:type] == "component_internal"}}

        # TODO: ganglia hack: remove after putting this info in teh r8 meta files
        (nested_objs[:nodes]||[]).each do |n|
          (n[:ports]||[]).each do |port|
            if port[:display_name] =~ /ganglia__server/
              port[:location] = "east"
            elsif  port[:display_name] =~ /ganglia__monitor/
              port[:location] = "west"
            end
          end
        end

# TODO: get node positions going for assemblies
        # compute uui positions
        parent_id = request.params["parent_id"]
        assembly_left_pos = request.params["assembly_left_pos"]
#        node_list = get_objects(:node,{:assembly_id=>id})

        dc_hash = get_object_by_id(parent_id,:datacenter)
        raise Error.new("Not implemented when parent_id is not a datacenter") if dc_hash.nil?

        # get the top most item in the list to set new positions
        top_node = {}
        top_most = 2000

#        node_list.each do |node|
        nested_objs[:nodes].each do |node|
#          node = create_object_from_id(node_hash[:id],:node)
          ui = node.get_ui_info(dc_hash)
          if ui and (ui[:top].to_i < top_most.to_i)
            left_diff = assembly_left_pos.to_i - ui[:left].to_i
            top_node = {:id=>node[:id],:ui=>ui,:left_diff=>left_diff}
            top_most = ui[:top]
          end
        end

        nested_objs[:nodes].each_with_index do |node,i|
          ui = node.get_ui_info(dc_hash)
          Log.error("no coordinates for node with id #{node[:id].to_s} in #{parent_id.to_s}") unless ui
          if ui
            if node[:id] == top_node[:id]
              ui[:left] = assembly_left_pos.to_i
            else
              ui[:left] = ui[:left].to_i + top_node[:left_diff].to_i
            end
          end
          node.update_ui_info!(ui,dc_hash)
          nested_objs[:nodes][i][:assembly_ui] = ui
        end

        nested_objs[:port_links].each_with_index do |link,i|
          nested_objs[:port_links][i][:ui] ||= {
            :type => R8::Config[:links][:default_type],
            :style => R8::Config[:links][:default_style]
          }
        end

        return {:data=>nested_objs}
# TODO: clean this up,hack to update UI params for newly cloned object
#      update_from_hash(id,{:ui=>hash["ui"]})

#      hash["redirect"] ? redirect_route = "/xyz/#{hash["redirect"]}/#{id.to_s}" : redirect_route = "/xyz/#{model_name()}/display/#{id.to_s}"

        if hash["model_redirect"]
          base_redirect = "/xyz/#{hash["model_redirect"]}/#{hash["action_redirect"]}"
          redirect_id =  hash["id_redirect"].match(/^\*/) ? id.to_s : hash["id_redirect"]
          redirect_route = "#{base_redirect}/#{redirect_id}"
          request_params = ''
          expected_params = ['model_redirect','action_redirect','id_redirect','target_id','target_model_name']
          request.params.each do |name,value|
            if !expected_params.include?(name)
              request_params << '&' if request_params != ''
              request_params << "#{name}=#{value}"
            end
          end
          ajax_request? ? redirect_route += '.json' : nil
          redirect_route << URI.encode("?#{request_params}") if request_params != ''
        else
          redirect_route = "/xyz/#{model_name()}/display/#{id.to_s}"
          ajax_request? ? redirect_route += '.json' : nil
        end

        redirect redirect_route
      end
    end

  end
end

