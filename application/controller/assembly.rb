module XYZ
  class AssemblyController < Controller

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
        name = component_list[index][:display_name]
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
        clone_opts = {:ret_new_obj_with_cols => [:id]}
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
