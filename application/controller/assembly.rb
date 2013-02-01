module DTK
  class AssemblyController < AuthController
    helper :assembly_helper

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

    def rest__remove_from_system()
      assembly = ret_assembly_instance_object()
      Assembly::Instance.delete(assembly.id_handle())
      rest_ok_response
    end

    def rest__add_component()
      assembly = ret_assembly_instance_object()
      component_template_idh = ret_request_param_id_handle(:component_template_id,Component::Template)
      #not checking here if node_id points to valid object; check is in add_component
      node_id = ret_non_null_request_params(:node_id)
      new_component_idh = assembly.add_component(id_handle(node_id,:node),component_template_idh)
      rest_ok_response(:component_id => new_component_idh.get_id())
    end

    def rest__delete_component()
      assembly = ret_assembly_instance_object()
      #not checking here if component_id points to valid object; check is in delete_component
      component_id = ret_non_null_request_params(:component_id)
      assembly.delete_component(id_handle(component_id,:component))
      rest_ok_response
    end

    #### end: create and delete actions ###

    #### list and info actions ###
    def rest__info()
      assembly,subtype = ret_assembly_params_object_and_subtype()
      rest_ok_response assembly.info(subtype) 
    end

    def rest__info_about()
      assembly,subtype = ret_assembly_params_object_and_subtype()
      about = ret_non_null_request_params(:about).to_sym
       unless AboutEnum[subtype].include?(about)
         raise ErrorUsage::BadParamValue.new(:about,AboutEnum[subtype])
       end
       
      rest_ok_response assembly.info_about(about)
    end
    AboutEnum = {
      :instance => [:nodes,:components,:tasks,:attributes],
      :template => [:nodes,:components,:targets]
    }
    FilterProc = {
      :attributes => lambda{|attr|not attr[:hidden]}
    }

    def rest__list_possible_add_ons()
      assembly = ret_assembly_instance_object()
      rest_ok_response assembly.get_service_add_ons()
    end

    def rest__get_attributes()
      filter = ret_request_params(:filter)
      filter = filter && filter.to_sym
      assembly = ret_assembly_instance_object()
      rest_ok_response assembly.get_attributes_print_form(filter)
    end

    def rest__list()
      subtype = ret_assembly_subtype()
      opts = {:version_suffix => true}.merge(ret_params_hash(:filter,:detail_level))
      result = 
        if subtype == :instance 
          Assembly::Instance.list(model_handle(),opts)
        else 
          project = get_default_project()
          Assembly::Template.list(model_handle(),opts.merge(:project_idh => project.id_handle()))
        end
      rest_ok_response result 
    end

    #### end: list and info actions ###

    #the body has an array each element of form
    # {:pattern => PAT, :value => VAL}
    #pat can be one of three forms
    #1 - an id
    #2 - a name of form ASSEM-LEVEL-ATTR or NODE/COMONENT/CMP-ATTR, or 
    #3 - a pattern (TODO: give syntax) that can pick out multiple vars
    # this returns same output as info about attributes, pruned for just new ones set
    def rest__set_attributes()
      assembly = ret_assembly_instance_object()
      av_pairs = ret_params_av_pairs()
      response = assembly.set_attributes(av_pairs)
      if response.empty?
        raise ErrorUsage.new("No attributes match")
      end
      rest_ok_response response
    end

    #### actions to promote changes from workspace to library ###
    def rest__promote_to_library()
      assembly = ret_assembly_instance_object()
      assembly.promote_to_library()
      rest_ok_response
    end

    def rest__create_new_template()
      assembly = ret_assembly_instance_object()
      service_module_name,assembly_template_name = ret_non_null_request_params(:service_module_name,:assembly_template_name)
      unless service_module = ServiceModule.find(model_handle(:service_module),service_module_name)
        raise ErrorUsage.new("Cannot find service nodule (#{service_module_name})")
      end
      assembly.create_new_template(service_module,assembly_template_name)
      rest_ok_response
    end
    #### end: actions to promote changes from workspace to library ###

    #### methods to modify the assembly instance
    def rest__add_sub_assembly()
      assembly = ret_assembly_instance_object()
      add_on_name = ret_non_null_request_params(:service_add_on_name)
      new_sub_assembly_idh = assembly.add_sub_assembly(add_on_name)
      rest_ok_response(:sub_assembly_id => new_sub_assembly_idh.get_id()) 
    end

    #### end: methods to modify the assembly instance

    #### method(s) related to staging assembly template
    def rest__stage()
      target = target_idh_with_default(request.params["target_id"]).create_object()
      assembly_template = ret_assembly_template_object()
      #TODO: if name given and not unique either reject or generate a -n suffix
      assembly_name = ret_request_params(:name) 
      new_assembly_obj = assembly_template.stage(target,assembly_name)
      rest_ok_response :assembly_id => new_assembly_obj[:id]
    end

    #### end: method(s) related to staging assembly template

    #### creates tasks to execute/converge assemblies and monitor status
    def rest__create_task()
      assembly = ret_assembly_instance_object()

      if assembly.is_stopped?
        validate_params = [
          :action => :start, 
          :params => {:assembly_id => assembly[:id]}, 
          :wait_for_complete => {:type => :assembly, :id => assembly[:id]}
        ]
        return rest_validate_response("Assembly is stopped, you need to start it.", validate_params)
      end

      commit_msg = ret_request_params(:commit_msg)
      task = Task.create_from_assembly_instance(assembly,:assembly,commit_msg)
      task.save!()
#TODO: this was call from gui commit window
#pp Attribute.augmented_attribute_list_from_task(task)
      rest_ok_response :task_id => task.id
    end

    #TODO: replace or given options to specify specific smoketests to run
    def rest__create_smoketests_task()
      assembly = ret_assembly_instance_object()
      commit_msg = ret_request_params(:commit_msg)
      task = Task.create_from_assembly_instance(assembly,:smoketest,commit_msg)
      task.save!()
      rest_ok_response :task_id => task.id
    end

    def rest__start()
      assembly = ret_assembly_instance_object()
      assembly_idh = ret_request_param_id_handle(:assembly_id,Assembly::Instance)
      node_pattern = ret_request_params(:node_pattern)

      # filters only stopped nodes for this assembly
      nodes = assembly.get_nodes(:id,:display_name,:type,:external_ref,:hostname_external_ref, :admin_op_status)

      nodes, is_valid, error_msg = nodes_valid_for_aws?(assembly[:id], nodes, node_pattern, :stopped)

      unless is_valid
        return rest_ok_response(:errors => [error_msg])
      end

      queue = SimpleActionQueue.new

      CreateThread.defer do
        # invoking command to start the nodes
        CommandAndControl.start_instances(nodes)

        # following task will when nodes ready assign elastic IP
        task = Task.task_when_nodes_ready_from_assembly(assembly_idh.create_object(),:assembly)
        task.save!()

        queue.set_result(:task_id => task.id)
      end

      rest_ok_response :action_results_id => queue.id
    end

    def rest__stop()
      assembly = ret_assembly_instance_object()
      node_pattern = ret_request_params(:node_pattern)
      nodes =  assembly.get_nodes(:id,:display_name,:type, :external_ref,:admin_op_status)

      nodes, is_valid, error_msg = nodes_valid_for_aws?(assembly[:id], nodes, node_pattern, :running)

      unless is_valid
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
    def nodes_valid_for_aws?(assembly_id, nodes, node_pattern, status_pattern)
      # check for pattern
      unless node_pattern.nil?
        regex = Regexp.new(node_pattern)
        nodes = nodes.select { |node| regex =~ node.id.to_s}
        if nodes.size == 0
          return nodes, false, "No nodes have been matched via ID ~ '#{node_pattern}'"
        end
      end
      # check if staged
      nodes.each do |node|
        if node[:type] == "staged"
          return nodes, false, "Nodes for assembly '#{assembly_id}' are 'staged' and as such cannot be started/stopped."
        end
      end

      # check for status -> this will translate to /running|pending/ and /stopped|pending/ checks
      filtered_nodes = nodes.select { |node| node[:admin_op_status] =~ Regexp.new("#{status_pattern.to_s}|pending") }
      if filtered_nodes.size == 0
        return nodes, false, "There are no #{status_pattern} nodes for assembly '#{assembly_id}'"
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

    def rest__task_status()
      assembly_id = ret_request_param_id(:assembly_id,Assembly::Instance)
      format = (ret_request_params(:format)||:hash).to_sym
      rest_ok_response Task::Status::Assembly.get_status(id_handle(assembly_id),:format => format)
    end

    ### mcollective actions
    def rest__initiate_get_netstats()
      assembly = ret_assembly_instance_object()
      queue = ActionResultsQueue.new
      assembly.initiate_get_netstats(queue)
      rest_ok_response :action_results_id => queue.id
    end
    
    def rest__get_action_results()
      #TODO: to be safe need to garbage collect on ActionResultsQueue in case miss anything
      action_results_id = ret_non_null_request_params(:action_results_id)
      ret_only_if_complete = ret_request_param_boolean(:return_only_if_complete)
      disable_post_processing = ret_request_param_boolean(:disable_post_processing)

      if ret_request_param_boolean(:using_simple_queue)
        rest_ok_response SimpleActionQueue.get_results(action_results_id)
      else
        rest_ok_response ActionResultsQueue.get_results(action_results_id,ret_only_if_complete,disable_post_processing)
      end
    end
    ### end: mcollective actions

#TDODO: got here in cleanup of rest calls

    def rest__list_smoketests()
      assembly_id = ret_non_null_request_params(:assembly_id)
      assembly = id_handle(assembly_id,:component).create_object()
      smoketests = assembly.list_smoketests()
      rest_ok_response smoketests
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

