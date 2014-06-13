module DTK
  class AssemblyController < AuthController
    helper :assembly_helper
    helper :task_helper

    #### create and delete actions ###
    #TODO: rename to delete_and_destroy
    def rest__delete()
      assembly_id,subtype = ret_assembly_params_id_and_subtype()
      if subtype == :template
        #returning module_repo_info so client can update this in its local module
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
      node_idh = ret_node_id_handle(:node_id,assembly)
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
      
      if cmp_full_name
        cmp_idh = ret_component_id_handle(:cmp_full_name,:assembly_id => assembly_id)
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
      node_id, component_id, attribute_id, return_json = ret_request_params(:node_id, :component_id, :attribute_id, :json_return)

      if return_json.eql?('true')
        rest_ok_response assembly.info(node_id, component_id, attribute_id)
      else
        rest_ok_response assembly.info(node_id, component_id, attribute_id), :encode_into => :yaml
      end
    end

    def rest__rename()
      assembly = ret_assembly_object()
      assembly_name = ret_non_null_request_params(:assembly_name)
      new_assembly_name = ret_non_null_request_params(:new_assembly_name)
      
      rest_ok_response assembly.rename(model_handle(), assembly_name, new_assembly_name)
    end

    #TODO: may be cleaner if we break into list_nodes, list_components with some shared helper functions
    def rest__info_about()
      node_id, component_id, detail_level, detail_to_include = ret_request_params(:node_id, :component_id, :detail_level, :detail_to_include)
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
      filter_proc = Proc.new do |e|
        ret_val = check_element(e,[:node,:id],node_id) && check_element(e,[:attribute,:component_component_id],component_id) && e
        ret_val = nil if (e[:attribute] and e[:attribute][:hidden])
        ret_val
      end 
      opts = Opts.new(:filter_proc => filter_proc, :detail_level => detail_level)
      opts.add_return_datatype!()
      if detail_to_include
        opts.merge!(:detail_to_include => detail_to_include.map{|r|r.to_sym})
        opts.add_value_to_return!(:datatype)
      end
      if about == :attributes
        if format == :yaml
          opts.merge!(:raw_attribute_value => true,:mark_unset_required => true)
        else
          opts.merge!(:truncate_attribute_values => true,:mark_unset_required => true)
        end
      end
      if node_id
        opts.merge!(:node_cmp_name => true)  unless node_id.empty?
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
      opts = {:donot_parse => true,:action_types=>[:assembly]}
      response = assembly.get_task_template_serialized_content(task_action,opts)
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
            component_module = create_obj(:module_name,ComponentModule)
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
      module_type = ret_non_null_request_params(:module_type)
      unless module_type.to_sym == :component_module
        raise Error.new("promote_module_changes only treats component_module type") 
      end
      module_name = ret_non_null_request_params(:module_name)
      component_module = create_obj(:module_name,ComponentModule)
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

    # checks element through set of fields
    def check_element(element, fields, element_id_val)
      return true if (element_id_val.nil? || element_id_val.empty?)
      return false if element.nil?
      temp_element = element.dup
      fields.each do |field|
        temp_element = temp_element[field]
        return false if temp_element.nil?
      end
      return (temp_element == element_id_val.to_i)
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
      #update_meta == true is the default
      unless !update_meta.nil? and !update_meta
        opts.merge!(:update_meta => true)
      end
      AttributeLink::AdHoc.create_adhoc_links(assembly,target_attr_term,source_attr_term,opts)
      rest_ok_response 
    end

    def rest__delete_service_link()
      port_link = ret_port_link()
      Model.delete_instance(port_link.id_handle())
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
      #TODO: stub
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
    #TODO: deprecate below for above
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
          opts = ret_params_hash(:filter,:detail_level)
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

    #### end: list and info actions ###
    #TODO: update what input can be
    #the body has an array each element of form
    # {:pattern => PAT, :value => VAL}
    #pat can be one of three forms
    #1 - an id
    #2 - a name of form ASSEM-LEVEL-ATTR or NODE/COMONENT/CMP-ATTR, or 
    #3 - a pattern (TODO: give syntax) that can pick out multiple vars
    # this returns same output as info about attributes, pruned for just new ones set
    #TODO: this is a minsnomer in that it can be used to just create attributes
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
      #update_meta == true is the default
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
      assembly_template_name,service_module_name = get_template_and_service_names_params(assembly)
      if assembly_template_name.nil? or service_module_name.nil?
        raise ErrorUsage.new("SERVICE-NAME/ASSEMBLY-NAME cannot be determined and must be explicitly given")
      end
      project = get_default_project()
      opts = ret_symbol_params_hash(:mode)
      service_module = Assembly::Template.create_or_update_from_instance(project,assembly,service_module_name,assembly_template_name,opts)
      clone_update_info = service_module.ret_clone_update_info()
      rest_ok_response clone_update_info
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

    def rest__add_component()
      assembly = ret_assembly_instance_object()
      component_template, component_title = ret_component_template_and_title_for_assembly(:component_template_id,assembly)
      #not checking here if node_id points to valid object; check is in add_component
      node_idh = ret_request_param_id_handle(:node_id,Node)
      new_component_idh = assembly.add_component(node_idh,component_template,component_title)
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
      target_id = ret_request_param_id_optional(:target_id, ::DTK::Target::Instance)
      target = target_idh_with_default(target_id).create_object(:model_name => :target_instance)
      assembly_template = ret_assembly_template_object()
      assembly_name = ret_request_params(:name) 
      new_assembly_obj = assembly_template.stage(target,assembly_name)
      response = {
        :new_service_instance => {
          :name => new_assembly_obj.display_name_print_form, 
          :id => new_assembly_obj.id()
        }
      }
      rest_ok_response(response,:encode_into => :yaml)
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
      task = nil

      if assembly.is_stopped?
        start_assembly = ret_request_params(:start_assembly)
        return rest_ok_response :confirmation_message=>true if start_assembly.nil?
        
        assembly_idh = ret_request_param_id_handle(:assembly_id,Assembly::Instance)
        node_pattern = ret_request_params(:node_pattern)

        # filters only stopped nodes for this assembly
        nodes = assembly.get_nodes(:id,:display_name,:type,:external_ref,:hostname_external_ref, :admin_op_status)

        assembly_name = Assembly::Instance.pretty_print_name(assembly)
        nodes, is_valid, error_msg = nodes_valid_for_aws?(assembly_name, nodes, node_pattern, :stopped)
        
        unless is_valid
          Log.info(error_msg)
          return rest_ok_response(:errors => [error_msg])
        end

        nodes_w_components = assembly.remove_empty_nodes(nodes, {:detail_level => 'nodes'})

        #TODO: not doing at this point puppet version per run; it just can be set when node is created
        opts = ret_params_hash(:commit_msg,:puppet_version)
        opts.merge!(:node => nodes_w_components.first) if (nodes_w_components.size == 1)
        task = Task.create_and_start_from_assembly_instance(assembly,opts)

        user_object = user_object  = ::DTK::CurrentSession.new.user_object()
        CreateThread.defer_with_session(user_object) do
          # invoking command to start the nodes
          CommandAndControl.start_instances(nodes_w_components) unless nodes_w_components.empty?
        end
      else
        raise ErrorUsage, "Task is already running on requested nodes. Please wait until task is complete" if assembly.are_nodes_running?
        #TODO: not doing at this point puppet version per run; it just can be set when node is created
        opts = ret_params_hash(:commit_msg,:puppet_version)
        task = Task.create_from_assembly_instance(assembly,opts)
      end

      task.save!()
      # TODO: this was called from gui commit window
      # pp Attribute.augmented_attribute_list_from_task(task)
      rest_ok_response :task_id => task.id
    end

    # leaving this commented until we test out if methode above works properly
    # def rest__create_task()
    #   assembly = ret_assembly_instance_object()
    #   if assembly.is_stopped?
    #     validate_params = [
    #       :action => :start, 
    #       :params => {:assembly => assembly[:id]}, 
    #       :wait_for_complete => {:type => :assembly, :id => assembly[:id]}
    #     ]
    #     return rest_validate_response("Assembly is stopped, you need to start it.", validate_params)
    #   end

    #   if assembly.are_nodes_running?
    #     raise ErrorUsage, "Task is already running on requested nodes. Please wait until task is complete"
    #   end

    #   opts = ret_params_hash(:commit_msg,:puppet_version)
    #   task = Task.create_from_assembly_instance(assembly,opts)
    #   task.save!()
    #   # TODO: this was called from gui commit window
    #   # pp Attribute.augmented_attribute_list_from_task(task)
    #   rest_ok_response :task_id => task.id
    # end

    # #TODO: replace or given options to specify specific smoketests to run
    # def rest__create_smoketests_task()
    #   assembly = ret_assembly_instance_object()
    #   opts = ret_params_hash(:commit_msg).merge(:component_type => :smoketest)
    #   task = Task.create_from_assembly_instance(assembly,opts)
    #   task.save!()
    #   rest_ok_response :task_id => task.id
    # end

    def rest__clear_tasks()
      assembly = ret_assembly_instance_object()
      assembly.clear_tasks()
      rest_ok_response
    end

    def rest__start()
      assembly     = ret_assembly_instance_object()
      assembly_idh = ret_request_param_id_handle(:assembly_id,Assembly::Instance)
      node_pattern = ret_request_params(:node_pattern)
      task         = nil

      # filters only stopped nodes for this assembly
      nodes = assembly.get_nodes(:id,:display_name,:type,:external_ref,:hostname_external_ref, :admin_op_status)
      assembly_name = Assembly::Instance.pretty_print_name(assembly)
      nodes, is_valid, error_msg = nodes_valid_for_aws?(assembly_name, nodes, node_pattern, :stopped)

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

      task = Task.task_when_nodes_ready_from_assembly(assembly_idh.create_object(),:assembly, opts)
      task.save!()

      # queue = SimpleActionQueue.new

      user_object  = ::DTK::CurrentSession.new.user_object()
      CreateThread.defer_with_session(user_object) do
        # invoking command to start the nodes
        CommandAndControl.start_instances(nodes)
      end

      # queue.set_result(:task_id => task.id)
      rest_ok_response :task_id => task.id
    end

    def rest__stop()
      assembly = ret_assembly_instance_object()
      node_pattern = ret_request_params(:node_pattern)
      nodes =  assembly.get_nodes(:id,:display_name,:type, :external_ref,:admin_op_status)
      assembly_idh = ret_request_param_id_handle(:assembly_id,Assembly::Instance)
      
      assembly_name = Assembly::Instance.pretty_print_name(assembly)
      nodes, is_valid, error_msg = nodes_valid_for_aws?(assembly_name, nodes, node_pattern, :running)

      unless is_valid
        Log.info(error_msg)
        return rest_ok_response(:errors => [error_msg])
      end
      
      CommandAndControl.stop_instances(nodes)

      rest_ok_response :status => :ok
    end

    ##
    # Method that will validate if nodes list is ready to started or stopped.
    #
    # * *Args*    :
    #   - +assembly_id+     ->  assembly id
    #   - +nodes+           ->  node list
    #   - +node_pattern+    ->  match id regexp pattern
    #   - +status_pattern+  ->  pattern to match node status
    # * *Returns* :
    #   - is valid flag
    #   - filtered nodes by pattern (if pattern not nil)
    #   - erorr message in case it is not valid
    #
    def nodes_valid_for_aws?(assembly_name, nodes, node_pattern, status_pattern)
      # check for pattern
      unless node_pattern.nil? || node_pattern.empty?
        regex = Regexp.new(node_pattern)

        #temp nodes_list
        nodes_list = nodes

        nodes = nodes.select { |node| regex =~ node.id.to_s}
        if nodes.size == 0
          nodes = nodes_list.select { |node| node_pattern.to_s.eql?(node.display_name.to_s)}
          return nodes, false, "No nodes have been matched via ID ~ '#{node_pattern}'." if nodes.size == 0
        end
      end
      # check if staged
      nodes.each do |node|
        if node[:type] == "staged"
          return nodes, false, "Nodes for assembly '#{assembly_name}' are 'staged' and as such cannot be started/stopped."
        end
      end

      # check for status -> this will translate to /running|pending/ and /stopped|pending/ checks
      filtered_nodes = nodes.select { |node| node[:admin_op_status] =~ Regexp.new("#{status_pattern.to_s}|pending") }
      if filtered_nodes.size == 0
        return nodes, false, "There are no #{status_pattern} nodes for assembly '#{assembly_name}'."
      end
      
      return filtered_nodes, true, nil      
    end

    def nodes_are_up?(assembly_name, nodes, status_pattern)
      # check if staged
      nodes.each do |node|
        if node[:type] == "staged"
          return nodes, false, "Serverspec tests cannot be executed on nodes that are 'staged'."
        end
      end

      # check for status -> this will translate to /running|pending/ and /stopped|pending/ checks
      filtered_nodes = nodes.select { |node| node[:admin_op_status] =~ Regexp.new("#{status_pattern.to_s}|pending") }
      if filtered_nodes.size == 0
        return nodes, false, "There are no #{status_pattern} nodes for assembly '#{assembly_name}'."
      end
      
      return filtered_nodes, true, nil      
    end

    def rest__initiate_get_log()
      assembly = ret_assembly_instance_object()
      params   = ret_params_hash(:node_identifier,:log_path, :start_line)
      queue = ActionResultsQueue.new
      assembly.initiate_get_log(queue, params)
      rest_ok_response :action_results_id => queue.id
    end

    def rest__initiate_ssh_pub_access()
      assembly = ret_assembly_instance_object()
      params   = ret_params_hash(:rsa_pub_name, :rsa_pub_key, :system_user)
      agent_action = ret_non_null_request_params(:agent_action)
      target_nodes = ret_node_id_handles(:target_nodes, assembly)

      # get models from idhs
      target_nodes = target_nodes.collect { |t_node| t_node.create_object().update_object!(:id, :display_name, :external_ref) }
      
      # check existance of key and system user in database
      system_user, key_name = params[:system_user], params[:rsa_pub_name]
      nodes = Component::Instance::Interpreted.find_candidates(assembly, system_user, key_name, agent_action, target_nodes)
      
      if agent_action.to_sym == :revoke_access && nodes.empty?
        raise ErrorUsage.new("Access #{target_nodes.empty? ? '' : 'on given nodes'} is not granted to system user '#{system_user}' with name '#{key_name}'")
      end

      if agent_action.to_sym == :grant_access && nodes.empty?
        raise ErrorUsage.new("Nodes already have access to system user '#{system_user}' with name '#{key_name}'")
      end

      queue    = ActionResultsQueue.new

      assembly.initiate_ssh_agent_action(agent_action.to_sym, queue, params, nodes)

      rest_ok_response :action_results_id => queue.id
    end

    def rest__list_ssh_access()
      assembly = ret_assembly_instance_object()

      rest_ok_response Component::Instance::Interpreted.list_ssh_access(assembly)
    end

    def rest__initiate_grep()
      assembly = ret_assembly_instance_object()
      params   = ret_params_hash(:node_pattern, :log_path, :grep_pattern, :stop_on_first_match)
      queue = ActionResultsQueue.new
      assembly.initiate_grep(queue, params)
      rest_ok_response :action_results_id => queue.id
    end

    def rest__task_status()
      assembly_id = ret_request_param_id(:assembly_id,Assembly::Instance)
      format = (ret_request_params(:format)||:hash).to_sym
      response = Task::Status::Assembly.get_status(id_handle(assembly_id),:format => format)
      rest_ok_response response
    end

    ### mcollective actions
    def rest__initiate_get_netstats()
      node_id = ret_non_null_request_params(:node_id)
      assembly = ret_assembly_instance_object()
      queue = ActionResultsQueue.new
      assembly.initiate_get_netstats(queue, node_id)
      rest_ok_response :action_results_id => queue.id
    end

    def rest__initiate_get_ps()
      node_id = ret_non_null_request_params(:node_id)
      assembly = ret_assembly_instance_object()
      queue = ActionResultsQueue.new
      assembly.initiate_get_ps(queue, node_id)
      rest_ok_response :action_results_id => queue.id
    end

    def rest__initiate_execute_tests()
      node_id, components = ret_non_null_request_params(:node_id, :components)
      assembly = ret_assembly_instance_object()

      #Logic for validation
      # filters only running nodes for this assembly
      nodes = assembly.get_nodes(:id,:display_name,:type,:external_ref,:hostname_external_ref, :admin_op_status)
      assembly_name = Assembly::Instance.pretty_print_name(assembly)
      nodes, is_valid, error_msg = nodes_are_up?(assembly_name, nodes, :running)

      unless is_valid
        Log.info(error_msg)
        return rest_ok_response(:errors => [error_msg])
      end

      #Logic for validation
      # restrict execution of execute-test if tasks are still executing
      #Commenting out to check if we have other way to get to the bottom of DTK-1477 issue
      #node_names = nodes.map { |node| node[:display_name] }
      #tasks_status = Task::Status::Assembly.get_status(id_handle(assembly[:id]),:format => :table)
      #tasks_status.each do |task_status|
      #  return rest_ok_response(:errors => ["Tasks are still executing. Please wait until tasks are completed to use execute-test functionality"]) if task_status[:status] == "executing"
      #end

      #Special case for preventing execution of agent on specific node that is not running
      matching_nodes = nodes.select { |node| node[:id] == node_id.to_i }
      if (!node_id.empty? && matching_nodes.empty?)
        error_msg = "Serverspec tests cannot be executed on nodes that are not 'running'."
        Log.info(error_msg)
        return rest_ok_response(:errors => [error_msg])
      end

      #Special case filtering of components from nodes that are not running and passing only those components for the execution
      node_names = Array.new
      nodes.each do |x|
        node_names << x[:display_name]
      end
      
      unless components.empty?
        components.reject! do |c|
          if c.include? "/"
            !node_names.include? c.split("/").first
          end
        end
      end

      queue = ActionResultsQueue.new
      assembly.initiate_execute_tests(queue, node_id, components)
      rest_ok_response :action_results_id => queue.id
    end

    def rest__initiate_execute_tests_v2()
      node_id, components = ret_non_null_request_params(:node_id, :components)
      assembly = ret_assembly_instance_object()
      project = get_default_project()
      #Logic for validation
      # filters only running nodes for this assembly
      nodes = assembly.get_nodes(:id,:display_name,:type,:external_ref,:hostname_external_ref, :admin_op_status)
      assembly_name = Assembly::Instance.pretty_print_name(assembly)
      nodes, is_valid, error_msg = nodes_are_up?(assembly_name, nodes, :running)

      unless is_valid
        Log.info(error_msg)
        return rest_ok_response(:errors => [error_msg])
      end

      #Special case for preventing execution of agent on specific node that is not running
      matching_nodes = nodes.select { |node| node[:id] == node_id.to_i }
      if (!node_id.empty? && matching_nodes.empty?)
        error_msg = "Serverspec tests cannot be executed on nodes that are not 'running'."
        Log.info(error_msg)
        return rest_ok_response(:errors => [error_msg])
      end

      #Special case filtering of components from nodes that are not running and passing only those components for the execution
      node_names = Array.new
      nodes.each do |x|
        node_names << x[:display_name]
      end
      
      unless components.empty?
        components.reject! do |c|
          if c.include? "/"
            !node_names.include? c.split("/").first
          end
        end
      end

      queue = ActionResultsQueue.new
      assembly.initiate_execute_tests_v2(project,queue, node_id, components)
      rest_ok_response :action_results_id => queue.id
    end
    
    def rest__get_action_results()
      #TODO: to be safe need to garbage collect on ActionResultsQueue in case miss anything
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

#TDODO: got here in cleanup of rest calls

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

      #restrict results to belong to library and not nested in assembly
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
        
#TODO: change after implementing all the new types and making generic icons for them
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

    #TODO: unify with clone(id)
    #clone assembly from library to target
    def stage()
      target_idh = target_idh_with_default(request.params["target_id"])
      assembly_id = ret_request_param_id(:assembly_id,::DTK::Assembly::Template)
      
      #TODO: if naem given and not unique either reject or generate a -n suffix
      assembly_name = ret_request_params(:name) 

      id_handle = id_handle(assembly_id)

      #TODO: need to copy in avatar when hash["ui"] is non null
      override_attrs = Hash.new
      override_attrs[:display_name] = assembly_name if assembly_name

      target_object = target_idh.create_object()
      clone_opts = {:ret_new_obj_with_cols => [:id,:type]}
      new_assembly_obj = target_object.clone_into(id_handle.create_object(),override_attrs,clone_opts)
      id = new_assembly_obj && new_assembly_obj.id()

      #compute ui positions
      nested_objs = new_assembly_obj.get_node_assembly_nested_objects()
      #TODO: this does not leverage assembly node relative positions
      nested_objs[:nodes].each do |node|
        target_object.update_ui_for_new_item(node[:id])
      end
      rest_ok_response(:assembly_id => id)
    end

    #clone assembly from library to target
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

        #TODO: need to copy in avatar when hash["ui"] is non null
        override_attrs = hash["ui"] ? {:ui=>hash["ui"]} : {}
        target_object = target_id_handle.create_object()
        clone_opts = {:ret_new_obj_with_cols => [:id,:type]}
        new_assembly_obj = target_object.clone_into(id_handle.create_object(),override_attrs,clone_opts)
        id = new_assembly_obj && new_assembly_obj.id()
        nested_objs = new_assembly_obj.get_node_assembly_nested_objects()

        #just want external ports
        (nested_objs[:nodes]||[]).each{|n|(n[:ports]||[]).reject!{|p|p[:type] == "component_internal"}}

        #TODO: ganglia hack: remove after putting this info in teh r8 meta files
        (nested_objs[:nodes]||[]).each do |n|
          (n[:ports]||[]).each do |port|
            if port[:display_name] =~ /ganglia__server/
              port[:location] = "east"
            elsif  port[:display_name] =~ /ganglia__monitor/
              port[:location] = "west"
            end
          end
        end

#TODO: get node positions going for assemblies
        #compute uui positions
        parent_id = request.params["parent_id"]
        assembly_left_pos = request.params["assembly_left_pos"]
#        node_list = get_objects(:node,{:assembly_id=>id})
  
        dc_hash = get_object_by_id(parent_id,:datacenter)
        raise Error.new("Not implemented when parent_id is not a datacenter") if dc_hash.nil?

        #get the top most item in the list to set new positions
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
#TODO: clean this up,hack to update UI params for newly cloned object
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

