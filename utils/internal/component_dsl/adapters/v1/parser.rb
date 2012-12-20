module DTK; class ComponentDSL; class V1
  class Parser < ::DTK::ComponentDSL::Parser
    def parse_components!(config_agent_type,meta_hash)
      impl_id = @impl_idh.get_id()
      module_branch_id = @module_branch_idh.get_id()
      remote_link_defs = Hash.new

      @components_hash = meta_hash.inject({}) do |h, (r8_hash_cmp_ref,cmp_info)|
        cmp_ref = component_ref(config_agent_type,r8_hash_cmp_ref)
        info = Hash.new
        cmp_info.each do |k,v|
          case k
          when "external_link_defs"
            v.each{|ld|(ld["possible_links"]||[]).each{|pl|pl.values.first["type"] = "external"}} #TODO: temp hack to put in type = "external"
            parsed_link_def = LinkDef.parse_serialized_form_local(v,config_agent_type,remote_link_defs,cmp_ref)
            (info["link_def"] ||= Hash.new).merge!(parsed_link_def)
          when "link_defs" 
            parsed_link_def = LinkDef.parse_serialized_form_local(v,config_agent_type,remote_link_defs,cmp_ref)
            (info["link_def"] ||= Hash.new).merge!(parsed_link_def)
          else
            info[k] = v
          end
        end
        info.merge!("implementation_id" => impl_id, "module_branch_id" => module_branch_id)
        h.merge(cmp_ref => info)
      end
      #process the link defs for remote components
      stored_cmps_hash = Hash.new
      process_remote_link_defs!(components_hash,remote_link_defs,container_idh)
    end

   private
    def db_update_form(cmps_input_hash,non_complete_cmps_input_hash,module_branch_idh)
      mark_as_complete_constraint = {:module_branch_id=>module_branch_idh.get_id()} #so only delete extra components that belong to same module
      cmp_db_update_hash = cmps_input_hash.inject(DBUpdateHash.new) do |h,(ref,hash_assigns)|
        h.merge(ref => db_update_form_aux(:component,hash_assigns))
      end.mark_as_complete(mark_as_complete_constraint)
      {"component" => cmp_db_update_hash.merge(non_complete_cmps_input_hash)}
    end

    def db_update_form_aux(model_name,hash_assigns)
      #TODO: think the key -> key.to_sym is not needed because they are keys
      ret = DBUpdateHash.new
      children_model_names = DB_REL_DEF[model_name][:one_to_many]||[]
      hash_assigns.each do |key,child_hash|
        key = key.to_sym
        if children_model_names.include?(key)
          child_model_name = key
          ret[key] = child_hash.inject(DBUpdateHash.new) do |h,(ref,child_hash_assigns)|
            h.merge(ref => db_update_form_aux(child_model_name,child_hash_assigns))
          end
          ret[key].mark_as_complete()
        else
          ret[key] = child_hash
        end
      end
      #mark as complete any child that does not appear in hash_assigns
      (children_model_names - hash_assigns.keys.map{|k|k.to_sym}).each do |key|
        ret[key] = DBUpdateHash.new().mark_as_complete()
      end
      ret
    end

    def component_ref_from_cmp_type(config_agent_type,component_type)
      "#{config_agent_type}-#{component_type}"
    end
    def component_ref(config_agent_type,r8_hash_cmp_ref)
      #TODO: may be better to have these prefixes already in r8 meta file
      "#{config_agent_type}-#{r8_hash_cmp_ref}"
    end

    #updates both cmps_hash and remote_link_defs
    def process_remote_link_defs!(cmps_hash,stored_cmps_hash,remote_link_defs,library_idh)
      return if remote_link_defs.empty?
      #process all remote_link_defs in this module
      remote_link_defs.each do |remote_cmp_type,remote_link_def|
        config_agent_type = remote_link_def.values.first[:config_agent_type]
        remote_cmp_ref = component_ref_from_cmp_type(config_agent_type,remote_cmp_type)
        if cmp_pointer = cmps_hash[remote_cmp_ref]
          remote_link_def.delete(:local_cmp_ref)
          (cmp_pointer["link_def"] ||= Hash.new).merge!(remote_link_def)
          remote_link_defs.delete(remote_cmp_type)
        end
      end

      #process remaining remote_link_defs to see if in stored modules
      return if remote_link_defs.empty?
      sp_hash = {
        :cols => [:id,:ref,:component_type],
        :filter => [:oneof,:component_type,remote_link_defs.keys]
      }
      stored_remote_cmps = library_idh.create_object().get_children_objs(:component,sp_hash,:keep_ref_cols=>true)
      ndx_stored_remote_cmps = stored_remote_cmps.inject({}){|h,cmp|h.merge(cmp[:component_type] => cmp)}
      remote_link_defs.each do |remote_cmp_type,remote_link_def|
        if remote_cmp = ndx_stored_remote_cmps[remote_cmp_type]
          remote_cmp_ref = remote_cmp[:ref]
          cmp_pointer = stored_cmps_hash[remote_cmp_ref] ||= {"link_def" => Hash.new}
          remote_link_def.delete(:local_cmp_ref)
          cmp_pointer["link_def"].merge!(remote_link_def)
          remote_link_defs.delete(remote_cmp_type)
        end
      end
      
      #if any remote_link_defs left they are dangling refs
      remote_link_defs.each do |remote_cmp_type,remote_cmp_info|
        set_to_dangling_link?(cmps_hash,remote_cmp_type,remote_cmp_info)
      end
    end

    def set_to_dangling_link?(cmps_hash,remote_cmp_type,remote_cmp_info)
      #TODO: may see if can put :local_cmp_ref so can use remote_cmp_info[:local_cmp_ref]
      if remote_cmp_info.size != 1
        Log.error("remote_cmp_info has unexpected size (<>1)")
        return
      end
      if local_cmp_ref = remote_cmp_info.values.first[:local_cmp_ref]
        local_ld_type = "local_#{remote_cmp_type}"
        if pntr = ((cmps_hash[local_cmp_ref]||{})["link_def"]||{})[local_ld_type]
          pntr.merge!(:dangling => true)
        end
      end
    end
  end

end; end; end

