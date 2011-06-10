#TODO: should this instead by a subclass of Component
module XYZ
  module ComponentTemplate
    def update_default(attribute_name,val,field_to_match=:display_name)
      tmpl_attr_obj =  get_virtual_attribute(attribute_name,[:id,:value_asserted],field_to_match)
      raise Error.new("cannot find attribute #{attribute_name} on component template") unless tmpl_attr_obj
      update(:updated => true)
      tmpl_attr_obj.update(:value_asserted => val)
      #update any instance that points to this template, which does not have an instance value asserted
      #TODO: can be more efficient by doing selct and update at same time
      base_sp_hash = {
        :model_name => :component,
        :filter => [:eq, :ancestor_id, id()],
        :cols => [:id]
      }
      join_array = 
        [{
           :model_name => :attribute,
           :convert => true,
           :join_type => :inner,
           :filter => [:and, [:eq, field_to_match, attribute_name], [:eq, :is_instance_value,false]],
           :join_cond => {:component_component_id => :component__id},
           :cols => [:id,:component_component_id]
         }]
      attr_ids_to_update = Model.get_objects_from_join_array(model_handle,base_sp_hash,join_array).map{|r|r[:attribute][:id]}
      unless attr_ids_to_update.empty?
        attr_mh = createMH(:attribute)
        attribute_rows = attr_ids_to_update.map{|attr_id|{:id => attr_id, :value_asserted => val}}
        Attribute.update_and_propagate_attributes(attr_mh,attribute_rows)
      end
    end

    def promote_template__new_version(new_version,library_idh)
      #TODO: can make more efficient by reducing number of seprate calss to db
      get_object_cols_and_update_ruby_obj!(:component_type,:extended_base_id,:implementation_id)
      #check if version exists already
      raise Error.new("component template #{self[:component_type]} (#{new_version}) already exists") if  matching_library_template_exists?(new_version,library_idh)

      #if project template has  been updated then need to generate
      proj_impl = id_handle(:model_name => :implementation, :id => self[:implementation_id]).create_object

      library_impl_idh = proj_impl.clone_into_library_if_needed(library_idh)

      override_attrs = {:version => new_version, :implementation_id => library_impl_idh.get_id()}
      library_idh.create_object().clone_into(self,override_attrs)
    end

   private

    def matching_library_template_exists?(version,library_idh)
      sp_hash = {
        :cols => [:id],
        :filter => [:and, 
                     [:eq, :library_library_id, library_idh.get_id()],
                     [:eq, :version, version],
                     [:eq, :component_type, self[:component_type]]]
      }
      Model.get_objects_from_sp_hash(model_handle,sp_hash).first
    end
  end
end
