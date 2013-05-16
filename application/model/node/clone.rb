module XYZ
  module NodeClone
    def add_model_specific_override_attrs!(override_attrs,target_obj)
      override_attrs[:type] ||= "staged"
      override_attrs[:ref] ||= SQL::ColRef.concat("s-",:ref)
      override_attrs[:display_name] ||= SQL::ColRef.concat{|o|["s-",:display_name,o.case{[[{:ref_num=> nil},""],o.concat("-",:ref_num)]}]}
    end

    def source_clone_info_opts()
      {:ret_new_obj_with_cols => [:id,:external_ref]}
    end

    def clone_pre_copy_hook(clone_source_object,opts={})
      if clone_source_object.model_handle[:model_name] == :component
        clone_source_object.clone_pre_copy_hook_into_node(self,opts)
      else
        clone_source_object
      end
    end

    def clone_post_copy_hook(clone_copy_output,opts={})
      component = clone_copy_output.objects.first
      clone_post_copy_hook__component(component,opts)
    end

    def clone_post_copy_hook__component(component,opts={})
      #if node is in assembly put component in the assembly
      if assembly_id = update_object!(:assembly_id)[:assembly_id]
        component.update(:assembly_id => assembly_id)
      end

      component_idh = component.id_handle

      #get the link defs/component_ports associated with components on the node; this is used
      #to determine if need to add internal links and for port processing
      node_link_defs_info = get_objs(:cols => [:node_link_defs_info])
      component_id = component.id()
      
      ###create needed component ports
      ndx_for_port_update = Hash.new
      component_link_defs = node_link_defs_info.map  do |r|
        link_def = r[:link_def]
        if link_def[:component_component_id] == component_id
          ndx_for_port_update[link_def[:id]] = r
          link_def 
        end
      end.compact

      create_opts = {:returning_sql_cols => [:link_def_id,:id,:display_name,:type,:connected]}
      new_cmp_ports = Port.create_component_ports?(component_link_defs,self,component,create_opts)

      #update node_link_defs_info with new ports
      new_cmp_ports.each do |port|
        ndx_for_port_update[port[:link_def_id]].merge!(:port => port)
      end

      #TODO: more efficient way to do this; instead include all needed columns in :returning_sql_cols above
      if opts[:outermost_ports] 
        port_mh = model_handle(:port)
        external_port_idhs = new_cmp_ports.map do |port_hash|
          port_mh.createIDH(:id => port_hash[:id]) if ["component_internal_external","component_external"].include?(port_hash[:type])
        end.compact
        unless external_port_idhs.empty?
          new_ports = Model.get_objs_in_set(external_port_idhs, {:cols => Port.common_columns})
          i18n = get_i18n_mappings_for_models(:component,:attribute)
          new_ports.map do |port|
            port.materialize!(Port.common_columns)
            port[:name] = get_i18n_port_name(i18n,port)
          end
          opts[:outermost_ports] += new_ports
        end
      end

      #### end create needed component ports ####

      unless opts[:donot_create_internal_links]
        LinkDef.create_needed_internal_links(self,component,node_link_defs_info)
      end

      unless opts[:donot_create_pending_changes]
        parent_action_id_handle = get_parent_id_handle()
        StateChange.create_pending_change_item(:new_item => component_idh, :parent => parent_action_id_handle)
      end
    end
  end
end
