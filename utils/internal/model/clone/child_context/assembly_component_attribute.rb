module XYZ
  class ChildContext 
    class AssemblyComponentAttribute < self
      private
      def initialize(clone_proc,hash)
        super
      end
      def ret_new_objs_info(db,field_set_to_copy,create_override_attrs)
        new_objs_info = super
        return new_objs_info if new_objs_info.empty?
        process_attribute_overrides(db,new_objs_info)
        new_objs_info
      end

      def process_attribute_overrides(db,new_objs_info)
        #TODO: may see if can do more efficiently using attribute_override col assembly_template_id
        #parent_objs_info has component info keys: :component_template_id, :component_ref_id and (which is the new component instance)

        attr_override_fs = Model::FieldSet.new(:attribute_override,[:display_name,:component_ref_id,{:attribute_value => :value_asserted}])
        attr_override_wc = nil
        attr_override_ds = Model.get_objects_just_dataset(model_handle.createMH(:attribute_override),attr_override_wc,Model::FieldSet.opt(attr_override_fs))

        cmp_mapping_rows = parent_objs_info.map{|r|Aux::hash_subset(r,[:component_ref_id,{:id => :component_component_id}])}
        cmp_mapping_ds = SQL::ArrayDataset.create(db,cmp_mapping_rows,model_handle.createMH(:cmp_mapping))

        attr_mapping_rows = new_objs_info.map{|r|Aux::hash_subset(r,[:component_component_id,:display_name,:id])}
        attr_mapping_ds = SQL::ArrayDataset.create(db,attr_mapping_rows,model_handle.createMH(:attr_mapping))

        select_ds = attr_override_ds.join_table(:inner,cmp_mapping_ds,[:component_ref_id]).join_table(:inner,attr_mapping_ds,[:component_component_id,:display_name])
        update_set_fs = Model::FieldSet.new(:attribute,[:value_asserted])
        Model.update_from_select(model_handle.createMH(:attribute),update_set_fs,select_ds,:constant_set_values => {:is_instance_value => true})
      end
    end
  end
end

