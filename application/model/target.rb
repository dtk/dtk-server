module XYZ
  class Target < Model
    def model_name() #TODO: remove temp datacenter->target
      :datacenter
    end
    ##
    def self.common_columns()
      [
       :id,
       :display_name,
       :name,
       :description,
       :type,
       :iaas_type,
       :project_id,
       :ui
      ]
    end
    ### virtual column defs
    def name()
      self[:display_name]
    end

    ######### Model apis
    def destroy_and_delete_nodes()
      nodes = get_objects_from_sp_hash(:cols => [:nodes]).map{|r|r[:node]}
      nodes.each{|n|n.destroy_and_delete()}
    end

    def get_violation_info(severity=nil)
      get_objects_from_sp_hash(:columns => [:violation_info]).map do |r|
        v = r[:violation]
        if severity.nil? or v[:severity] == severity
          v.merge(:target_node_display_name => (r[:node]||{})[:display_name])
        end
      end.compact
    end

    def add_item(source_id_handle,override_attrs={})
      #TODO: need to copy in avatar when hash["ui"] is non null
      override_attrs ||= {}
      source_obj = source_id_handle.create_object()
      clone_opts = source_obj.source_clone_info_opts()
      new_obj = clone_into(source_obj,override_attrs,clone_opts)
      new_obj && new_obj.id()
    end

    def self.get_port_links(id_handles,type="l4")
      return Array.new if id_handles.empty?

      node_id_handles = id_handles.select{|idh|idh[:model_name] == :node}
      if node_id_handles.size < id_handles.size
        models_not_treated = id_handles.reject{|idh|idh[:model_name] == :node}.map{idh|idh[:model_name]}.unique
        Log.error("Item list for Target.get_port_links has models not treated (#{models_not_treated.join(",")}; they will be ignored")
      end

      raw_link_list = Node.get_port_links(node_id_handles,type)

      link_list = Array.new
      raw_link_list.each do |el|
        [:input_port_links,:output_port_links].each do |dir|
          next unless el.has_key?(dir)
          el[dir].each do |port_link|
            port_dir = dir == :input_port_links ? "input" : "output"
            port_id = dir == :input_port_links ? port_link[:input_id] : port_link[:output_id]
            other_end_id = dir == :input_port_links ? port_link[:output_id] : port_link[:input_id]
            link_list << {
              :id => port_link[:id],
              :item_id => el[:id],
              :port_id => port_id,
              :type => type,
              :port_dir => port_dir,
              :other_end_id => other_end_id
            }
          end
        end
      end
      link_list
    end

    #### clone helping functions
    def clone_post_copy_hook(clone_copy_output,opts={})
      case clone_copy_output.model_name()
       when :component 
        clone_post_copy_hook__component(clone_copy_output,opts)
       when :node
        clone_post_copy_hook__node(clone_copy_output,opts)        
       else #TODO: catchall taht will be expanded
        new_id_handle = clone_copy_output.id_handles.first
        StateChange.create_pending_change_item(:new_item => new_id_handle, :parent => id_handle())
      end
    end

   private
    def sub_item_model_names()
      [:node,:node_group]
    end

    def clone_post_copy_hook__node(clone_copy_output,opts)
      update_object!(:iaas_type,:iaas_parameters)
      new_id_handle = clone_copy_output.id_handles.first
      #add external ref values from target to node if node does not have them
      #assuming passed already check whether node consistent requirements with target
      #TODO: not handling yet constraint form where set of possibilities given
      node = clone_copy_output.objects.first
      node_ext_ref = node[:external_ref]
      self[:iaas_parameters].each do |k,v|
        unless node_ext_ref.has_key?(k)
          node_ext_ref[k] = v
        end
      end
      node.update(:external_ref => node_ext_ref)
      StateChange.create_pending_change_item(:new_item => new_id_handle, :parent => id_handle())
    end

    def clone_post_copy_hook__component(clone_copy_output,opts)
      #TODO: right now this wil be just a composite component and clone_copy_output will be off form assembly - nodee - component
      #TODO: may put nodes under "install of assembly"
      level = 1
      node_idhs = clone_copy_output.children_id_handles(level,:node)
      node_new_items = node_idhs.map{|idh|{:new_item => idh, :parent => id_handle()}}
      return if node_new_items.empty?
      node_sc_idhs = StateChange.create_pending_change_items(node_new_items)

      indexed_node_info = Hash.new #TODO: may have state create this as output
      node_sc_idhs.each_with_index{|sc_idh,i|indexed_node_info[node_idhs[i].get_id()] = sc_idh}

      level = 2
      component_new_items = clone_copy_output.children_hash_form(level,:component).map do |child_hash| 
        {:new_item => child_hash[:id_handle], :parent => indexed_node_info[child_hash[:clone_parent_id]]}
      end
      return if component_new_items.empty?
      StateChange.create_pending_change_items(component_new_items)
    end
  end
  Datacenter = Target #TODO: remove temp datacenter->target
end

