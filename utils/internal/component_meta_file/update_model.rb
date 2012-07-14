module DTK; class ComponentMetaFile
  module UpdateModelMixin
    def update_model()
      self.class.add_components_from_r8meta(@container_idh,@config_agent_type,@impl_idh,@input_hash)
    end
  end

  module UpdateModelClassMixin
    #TODO: make private after removing all non class references to it
    def add_components_from_r8meta(container_idh,config_agent_type,impl_idh,meta_hash)
      impl_id = impl_idh.get_id()
      remote_link_defs = Hash.new
      cmps_hash = meta_hash.inject({}) do |h, (r8_hash_cmp_ref,cmp_info)|
        info = Hash.new
        cmp_info.each do |k,v|
          case k
          when "external_link_defs"
            v.each{|ld|(ld["possible_links"]||[]).each{|pl|pl.values.first["type"] = "external"}} #TODO: temp hack to put in type = "external"
            parsed_link_def = LinkDef.parse_serialized_form_local(v,config_agent_type,remote_link_defs)
            (info["link_def"] ||= Hash.new).merge!(parsed_link_def)
          when "link_defs" 
            parsed_link_def = LinkDef.parse_serialized_form_local(v,config_agent_type,remote_link_defs)
            (info["link_def"] ||= Hash.new).merge!(parsed_link_def)
          else
            info[k] = v
          end
        end
        info.merge!("implementation_id" => impl_id)
        cmp_ref = component_ref(config_agent_type,r8_hash_cmp_ref)
        h.merge(cmp_ref => info)
      end
      #process the link defs for remote components
      process_remote_link_defs!(cmps_hash,remote_link_defs,container_idh)

      #data_source_update_hash form used so can annotate subcomponents with "is complete" so will delete items taht are removed
      db_update_hash = db_update_form(cmps_hash)
      Model.input_hash_content_into_model(container_idh,db_update_hash)
      sp_hash =  {
        :cols => [:id,:display_name], 
        :filter => [:and,[:oneof,:ref,cmps_hash.keys],[:eq,:library_library_id,container_idh.get_id()]]
      }
      component_idhs = Model.get_objs(container_idh.create_childMH(:component),sp_hash).map{|r|r.id_handle()}
      component_idhs
    end
   private
    def db_update_form(cmps_input_hash)
      cmp_db_update_hash = cmps_input_hash.inject(DBUpdateHash.new) do |h,(ref,hash_assigns)|
        h.merge(ref => db_update_form_aux(:component,hash_assigns))
      end.mark_as_complete()
      {"component" => cmp_db_update_hash}
    end

    def db_update_form_aux(model_name,hash_assigns)
      ret = DBUpdateHash.new
      children_model_names = DB_REL_DEF[model_name][:one_to_many]||[]
      hash_assigns.each do |key,child_hash|
        if children_model_names.include?(key.to_sym)
          child_model_name = key.to_sym
          ret[key] = child_hash.inject(DBUpdateHash.new) do |h,(ref,child_hash_assigns)|
            h.merge(ref => db_update_form_aux(child_model_name,child_hash_assigns))
          end
          ret[key].mark_as_complete()
        else
          ret[key] = child_hash
        end
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
    def process_remote_link_defs!(cmps_hash,remote_link_defs,library_idh)
      return if remote_link_defs.empty?
      #process all remote_link_defs in this module
      remote_link_defs.each do |remote_cmp_type,remote_link_def|
        config_agent_type = remote_link_def.values.first[:config_agent_type]
        remote_cmp_ref = component_ref_from_cmp_type(config_agent_type,remote_cmp_type)
        if cmp_pointer = cmps_hash[remote_cmp_ref]
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
          cmp_pointer = cmps_hash[remote_cmp_ref] ||= {"link_def" => Hash.new}
          cmp_pointer["link_def"].merge!(remote_link_def)
          remote_link_defs.delete(remote_cmp_type)
        end
      end
      
      #if any remote_link_defs left they are dangling refs
      remote_link_defs.keys.each do |remote_cmp_type|
        Log.error("link def references a remote component (#{remote_cmp_type}) that does not exist")
      end
    end
  end
end; end

