class DTK::ComponentMetaFile
  module UpdateModelClassMixin
    r8_nested_require('update_model','add_to_model')
    include AddToModelClassMixin
  end
  module UpdateModelMixin
    def update_model()
      #partition into to_add, to_delete,a dn to_modify
      existing_cmps = get_existing_component_ws_templates(@impl_idh.createMH(:component),@impl_idh,@project_idh)
      
      existing_cmp_info = existing_cmps.inject(Hash.new){|h,cmp|h.merge(cmp[:component_type] => {:found => nil, :component => cmp})}
      cmp_idhs_to_delete = Array.new
      input_cmps_to_add = Hash.new
      input_cmps_to_modify = Hash.new
      @input_hash.each do |ref,content|
        cmp_type = content["component_type"]
        if pntr = existing_cmp_info[cmp_type]
          input_cmps_to_modify.merge!(ref => content)
          pntr[:found] = true
        else
          input_cmps_to_add.merge!(ref => content)
        end
      end
      cmp_idhs_to_delete = existing_cmp_info.values.reject{|cmp|cmp[:found]}.map{|cmp|cmp[:component].id_handle()}  

      delete_removed_components(cmp_idhs_to_delete)
      add_new_components(input_cmps_to_add)
      modify_existing_components(input_cmps_to_modify)
    end

   private
    def delete_removed_components(cmp_idhs_to_delete)
#TODO: stub until make sure called with right values
return
      return if cmp_idhs_to_delete.empty?
      Model.delete_instances(cmp_idhs_to_delete)  
    end

    def add_new_components(input_cmps)
      return if input_cmps.empty?
      #TODO: stub
    end

    def modify_existing_components(input_cmps)
      return if input_cmps.empty?
      ndx_cmps_to_update = Hash.new
      process_external_link_defs!(ndx_cmps_to_update,input_cmps)
      unless ndx_cmps_to_update.empty?
        Model.update_from_rows(@impl_idh.createMH(:component),ndx_cmps_to_update.values,:partial_value=>true)
      end
    end

    def process_external_link_defs!(ndx_cmps_to_update,input_cmps)
      link_defs = input_cmps.inject({}) do |h,(cmp_type,info)|
        ext_link_defs = info["external_link_defs"]
        ext_link_defs ? h.merge(cmp_type => ext_link_defs) : h
      end
      return if link_defs.empty?
      input_cmps.each do |r|
        p = ndx_cmps_to_update[r[:id]] ||= {:id => r[:id]} 
        p[:link_defs] ||= Hash.new
        p[:link_defs]["external"] = link_defs[r[:component_type]]
      end
    end

    def get_existing_component_ws_templates(cmp_mh,impl_idh,project_idh)
      sp_hash = {
        :model_name => :component,
        :filter => [:and, 
                    [:eq, :implementation_id, impl_idh.get_id()],
                    [:eq, :project_project_id, project_idh.get_id()]], #to make sure that this is a workspace template not an instance 
        :cols => [:id,:component_type]
      }
      Model.get_objs(cmp_mh,sp_hash)
    end
  end
end
