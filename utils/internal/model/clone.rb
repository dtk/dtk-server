module XYZ
  module CloneClassMixins
    def clone(id_handle,target_id_handle,override_attrs={},opts={})
      add_model_specific_override_attrs!(override_attrs)
      new_id_handle = clone_copy(id_handle,[target_id_handle],override_attrs,opts).first
      raise Error.new("cannot clone") unless new_id_handle
      #calling with respect to target
      model_class(target_id_handle[:model_name]).clone_post_copy_hook(new_id_handle,target_id_handle,opts)
      return new_id_handle.get_id()
    end

   protected
    # to be optionally overwritten by object representing the source
    def add_model_specific_override_attrs!(override_attrs)
    end

    # to be optionally overwritten by object representing the target
    def clone_post_copy_hook(new_id_handle,target_id_handle,opts={})
    end

   private

    #copy part of clone
    #targets is a list of id_handles, each with same model_name 
    def clone_copy(source_id_handle,targets,recursive_override_attrs={},opts={})
      #TODO: facttor back in functionality that clone_helper provided for non-parent foreign keys that may point to what is cloned
      return Array.new if targets.empty?

      source_model_name = source_id_handle[:model_name]
      source_model_handle = source_id_handle.createMH()
      source_parent_id_col = source_model_handle.parent_id_field_name()

      override_attrs = ret_real_columns(source_model_handle,recursive_override_attrs)

      target_parent_model_name = targets.first[:model_name]
      target_model_handle = source_id_handle.createMH(:parent_model_name => target_parent_model_name)
      target_parent_id_col = target_model_handle.parent_id_field_name()

      targets_rows = targets.map{|id_handle|{target_parent_id_col => id_handle.get_id()}}
      targets_ds = SQL::ArrayDataset.create(db,targets_rows,ModelHandle.new(source_id_handle[:c],:target))

      source_wc = {:id => source_id_handle.get_id()}

      remove_cols = (source_parent_id_col == target_parent_id_col ? [:id,:local_id] : [:id,:local_id,source_parent_id_col])
      field_set_to_copy = Model::FieldSet.all_real(source_model_name).remove_cols(*remove_cols)
      source_fs = Model::FieldSet.opt(field_set_to_copy.remove_cols(target_parent_id_col))
      source_ds = get_objects_just_dataset(source_model_handle,source_wc,source_fs)

      select_ds = targets_ds.join_table(:inner,source_ds)
      dups_allowed_for_cmp = true #TODO stub
      create_opts = {:duplicate_refs => dups_allowed_for_cmp ? :allow : :prune_duplicates}
      create_override_attrs = override_attrs.merge(:ancestor_id => source_id_handle.get_id()) 
      new_id_handles = create_from_select(target_model_handle,field_set_to_copy,select_ds,create_override_attrs,create_opts)
      return new_id_handles if new_id_handles.empty?
      
      #iterate over all children objects
      new_id_handles.first.get_children_model_handles.each do |child_model_handle|
        child_override_attrs = ret_child_override_attrs(child_model_handle,recursive_override_attrs)
        clone_copy_child_objects(child_model_handle,source_id_handle,new_id_handles,child_override_attrs)
      end
      new_id_handles
    end

    def clone_copy_child_objects(child_model_handle,base_id_handle,targets,recursive_override_attrs={})
      #TODO: facttor back in clone_helper
      child_model_name = child_model_handle[:model_name]
      child_parent_id_col = child_model_handle.parent_id_field_name()

      targets_wc = targets.map{|id_handle|{child_parent_id_col => id_handle.get_id()}}
      targets_ds = SQL::ArrayDataset.create(db,targets_wc,ModelHandle.new(base_id_handle[:c],:target))

      field_set_to_copy = Model::FieldSet.all_real(child_model_name).remove_cols(:id,:local_id)
      child_wc = {child_parent_id_col => base_id_handle.get_id()}
      child_fs = Model::FieldSet.opt(field_set_to_copy.remove_cols(child_parent_id_col))
      child_ds = get_objects_just_dataset(child_model_handle,child_wc,child_fs)

      select_ds = targets_ds.join_table(:inner,child_ds)
      create_opts = {:duplicate_refs => :no_check}
      create_override_attrs = ret_real_columns(child_model_handle,recursive_override_attrs)
      new_id_handles = create_from_select(child_model_handle,field_set_to_copy,select_ds,create_override_attrs,create_opts)
      return new_id_handles if new_id_handles.empty?
      
      #NOTE: iterate over all all children children think can recursively call clone_copy_child_objects if change base_id_handle to base_id_handles
      new_id_handles
    end

    def ret_child_override_attrs(child_model_handle,recursive_override_attrs)
      recursive_override_attrs[(child_model_handle[:model_name])]||{}
    end
    def ret_real_columns(model_handle,recursive_override_attrs)
      fs = Model::FieldSet.all_real(model_handle[:model_name])
      recursive_override_attrs.reject{|k,v| not fs.include_col?(k)}
    end
  end
end
