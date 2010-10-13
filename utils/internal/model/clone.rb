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

    def deprecate_clone(id_handle,target_id_handle,override_attrs={},opts={})
      source_obj = opts[:source_obj] || get_object_deep(id_handle)
      raise Error.new("clone source (#{id_handle}) not found") if source_obj.nil? 
      process_override_attributes!(source_obj,override_attrs)
      new_id_handle = deprecate_clone_copy(id_handle,source_obj,target_id_handle,opts)
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
    def clone_copy(source_id_handle,targets,override_attrs={},opts={})
      #TODO: facttor back in clone_helper
      return Array.new if targets.empty?

      source_model_name = source_id_handle[:model_name]
      target_parent_model_name = targets.first[:model_name]

      source_model_handle = source_id_handle.createMH()
      source_parent_id_col = source_model_handle.parent_id_field_name()

      target_model_handle = source_id_handle.createMH(:parent_model_name => target_parent_model_name)
      target_parent_id_col = target_model_handle.parent_id_field_name()

      targets_wc = targets.map{|id_handle|{target_parent_id_col => id_handle.get_id()}}
      targets_ds = SQL::ArrayDataset.create(db,targets_wc,:target)

      source_wc = {:id => source_id_handle.get_id()}

      field_set_to_copy = Model::FieldSet.all_real(source_model_name).remove_cols(*([:id,:local_id]+[source_parent_id_col]))
      source_fs = Model::FieldSet.opt(field_set_to_copy.remove_cols(target_parent_id_col))
      source_ds = get_objects_just_dataset(source_model_handle,source_wc,source_fs)

      select_ds = targets_ds.graph(:inner,source_ds)
      dups_allowed_for_cmp = true #TODO stub
      create_opts = {:duplicate_refs => dups_allowed_for_cmp ? :allow : :prune_duplicates, :sync_display_name_with_ref => true}
      create_override_attrs = override_attrs.merge(:ancestor_id => source_id_handle.get_id()) 
      new_ids = create_from_select(target_model_handle,field_set_to_copy,select_ds,create_override_attrs,create_opts)
      return Array.new if new_ids.empty?
      ret = new_ids.map{|id|source_id_handle.createIH({:id => id,:parent_model_name => target_parent_model_name})}

      
      #TODO: iterate overall all children
      ret.first.get_children_model_handles.each{|child_model_handle|pp child_model_handle}
      ret
    end
  end
end
