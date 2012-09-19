module DTK
  class AssemblyController < Controller
    helper :assembly_helper
    #### create and delete actions ###
    def rest__delete()
      assembly_id,subtype = ret_assembly_params_id_and_subtype()
      Assembly.delete(id_handle(assembly_id),subtype)
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
      opts = ret_params_hash(:filter,:detail_level)
      rest_ok_response assembly.info_about(about)
    end
    AboutEnum = {
      :instance => [:nodes,:components,:tasks],
      :template => [:nodes,:components,:targets]
    }

    def rest__list()
      subtype = ret_assembly_subtype()
      opts = ret_params_hash(:filter,:detail_level)
      result = 
        if subtype == :instance 
          Assembly.list_from_target(model_handle(),opts)
        else 
          Assembly.list_from_library(model_handle(),opts) 
        end
      rest_ok_response result 
    end
    #### end: list and info actions ###

    def rest__task_status()
      assembly_id = ret_request_param_id(:assembly_id,AssemblyInstance)
      rest_ok_response Task.assembly_task_status(id_handle(assembly_id))
    end

#TDODO: got here in cleanup of rest calls
    #creates task to execute/converge assembly
    def rest__create_task()
      #assembly_id should be a target assembly instance
      assembly_id = ret_request_param_id(:assembly_id,::DTK::AssemblyInstance)
      task = Task.create_from_assembly_instance(id_handle(assembly_id))
      task.save!()
      rest_ok_response :task_id => task.id
    end

    #TODO: replace or given options to specify specific smoketests to run
    def rest__create_smoketests_task()
      #assembly_id should be a target assembly instance
      assembly_id = ret_non_null_request_params(:assembly_id)
      task = Task.create_from_assembly_instance(id_handle(assembly_id),:smoketest)
      task.save!()
      rest_ok_response :task_id => task.id
    end

    def rest__list_smoketests()
      assembly_id = ret_non_null_request_params(:assembly_id)
      assembly = id_handle(assembly_id,:component).create_object()
      smoketests = assembly.list_smoketests()
      rest_ok_response smoketests
    end

    def rest__set_attributes()
      assembly_id,pattern,value = ret_non_null_request_params(:assembly_id,:pattern,:value)
      assembly = id_handle(assembly_id,:component).create_object()
      assembly.set_attributes(pattern,value)
      rest_ok_response
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
        body_value = ''
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
    def rest__stage()
      target_idh = target_idh_with_default(request.params["target_id"])
      assembly_id = ret_request_param_id(:assembly_id,::DTK::AssemblyTemplate)
      
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
