module DTK; class ComponentDSL; class V1
  class Parser < ::DTK::ComponentDSL::Parser
    def parse_components!(config_agent_type,dsl_hash)
      impl_id = impl_idh.get_id()
      module_branch_id = module_branch_idh.get_id()

      @components_hash = dsl_hash.inject({}) do |h, (r8_hash_cmp_ref,cmp_info)|
        cmp_ref = component_ref(config_agent_type,r8_hash_cmp_ref)
        info = Hash.new
        cmp_info.each do |k,v|
          case k
          when "external_link_defs"
            v.each{|ld|(ld["possible_links"]||[]).each{|pl|pl.values.first["type"] = "external"}} #TODO: temp hack to put in type = "external"
            parsed_link_def = LinkDef.parse_serialized_form_local(v,config_agent_type,@remote_link_defs,cmp_ref)
            (info["link_def"] ||= Hash.new).merge!(parsed_link_def)
          when "link_defs" 
            parsed_link_def = LinkDef.parse_serialized_form_local(v,config_agent_type,@remote_link_defs,cmp_ref)
            (info["link_def"] ||= Hash.new).merge!(parsed_link_def)
          else
            info[k] = v
          end
        end
        info.merge!("implementation_id" => impl_id, "module_branch_id" => module_branch_id)
        h.merge(cmp_ref => info)
      end
      #process the link defs for remote components
      process_remote_link_defs!(container_idh)
    end

   private
    def component_ref_from_cmp_type(config_agent_type,component_type)
      "#{config_agent_type}-#{component_type}"
    end
    def component_ref(config_agent_type,r8_hash_cmp_ref)
      #TODO: may be better to have these prefixes already in r8 dsl file
      "#{config_agent_type}-#{r8_hash_cmp_ref}"
    end

    #updates both @components_hash and @remote_link_defs
    def process_remote_link_defs!(library_idh)
      return if @remote_link_defs.empty?
      #process all @remote_link_defs in this module
      @remote_link_defs.each do |remote_cmp_type,remote_link_def|
        config_agent_type = remote_link_def.values.first[:config_agent_type]
        remote_cmp_ref = component_ref_from_cmp_type(config_agent_type,remote_cmp_type)
        if cmp_pointer = @components_hash[remote_cmp_ref]
          remote_link_def.delete(:local_cmp_ref)
          (cmp_pointer["link_def"] ||= Hash.new).merge!(remote_link_def)
          @remote_link_defs.delete(remote_cmp_type)
        end
      end

      #process remaining @remote_link_defs to see if in stored modules
      return if @remote_link_defs.empty?
      sp_hash = {
        :cols => [:id,:ref,:component_type],
        :filter => [:oneof,:component_type,@remote_link_defs.keys]
      }
      stored_remote_cmps = library_idh.create_object().get_children_objs(:component,sp_hash,:keep_ref_cols=>true)
      ndx_stored_remote_cmps = stored_remote_cmps.inject({}){|h,cmp|h.merge(cmp[:component_type] => cmp)}
      @remote_link_defs.each do |remote_cmp_type,remote_link_def|
        if remote_cmp = ndx_stored_remote_cmps[remote_cmp_type]
          remote_cmp_ref = remote_cmp[:ref]
          cmp_pointer = @stored_components_hash[remote_cmp_ref] ||= {"link_def" => Hash.new}
          remote_link_def.delete(:local_cmp_ref)
          cmp_pointer["link_def"].merge!(remote_link_def)
          @remote_link_defs.delete(remote_cmp_type)
        end
      end
      
      #if any @remote_link_defs left they are dangling refs
      @remote_link_defs.each do |remote_cmp_type,remote_cmp_info|
        set_to_dangling_link?(remote_cmp_type,remote_cmp_info)
      end
    end

    def set_to_dangling_link?(remote_cmp_type,remote_cmp_info)
      #TODO: may see if can put :local_cmp_ref so can use remote_cmp_info[:local_cmp_ref]
      if remote_cmp_info.size != 1
        Log.error("remote_cmp_info has unexpected size (<>1)")
        return
      end
      if local_cmp_ref = remote_cmp_info.values.first[:local_cmp_ref]
        local_ld_type = "local_#{remote_cmp_type}"
        if pntr = ((@components_hash[local_cmp_ref]||{})["link_def"]||{})[local_ld_type]
          pntr.merge!(:dangling => true)
        end
      end
    end
  end

end; end; end

