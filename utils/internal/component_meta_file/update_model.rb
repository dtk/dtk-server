module DTK
  module ComponentMetaFileUpdateModelMixin
    def update_model()
      #TODO: right now just processing changes to link defs
      ndx_cmps_to_update = Hash.new
      process_external_link_defs!(ndx_cmps_to_update)
      unless ndx_cmps_to_update.empty?
        Model.update_from_rows(@impl_idh.createMH(:component),ndx_cmps_to_update.values,:partial_value=>true)
      end
    end

   private
    def process_external_link_defs!(ndx_cmps_to_update)
      link_defs = @hash_content.inject({}) do |h,(cmp_type,info)|
        ext_link_defs = info["external_link_defs"]
        ext_link_defs ? h.merge(cmp_type => ext_link_defs) : h
      end
      return if link_defs.empty?
      #get the matching components in the project implementation and their instantaions
      updates = get_matching_component_ws_templates(link_defs.keys)
      if updates.empty?
        Log.error("unexpected that cant find any components that match")
        return 
      end
      updates.each do |r|
        p = ndx_cmps_to_update[r[:id]] ||= {:id => r[:id]} 
        p[:link_defs] ||= Hash.new
        p[:link_defs]["external"] = link_defs[r[:component_type]]
      end
    end

    ##TODO: deprecate
    def get_matching_component_ws_templates(cmp_type_array)
      sp_hash = {
        :model_name => :component,
        :filter => [:and, 
                    [:eq, :implementation_id, @impl_idh.get_id()],
                    [:eq, :project_project_id, @project_idh.get_id()], #to make sure that this is a workspace template not an instance 
                    [:oneof, :component_type, cmp_type_array]],
        :cols => [:id,:component_type]
      }
      Model.get_objs(@impl_idh.createMH(:component),sp_hash)
    end
  end
end
