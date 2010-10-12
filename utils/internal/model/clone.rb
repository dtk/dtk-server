module XYZ
  module CloneClassMixins

    def clone(id_handle,target_id_handle,override_attrs={},opts={})
      new_id_handle = clone_copy(id_handle,[target_id_handle],override_attrs,opts).first
      return nil unless new_id_handle
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
    def set_model_specific_override_attrs!(override_attrs,source_attrs,ref)
    end

    # to be optionally overwritten by object representing the target
    def clone_post_copy_hook(new_id_handle,target_id_handle,opts={})
    end

   private
    #modifies object being copied source_obj if needed
    def process_override_attributes!(source_obj,override_attrs)
      #source_obj is of form {ref => {attr1 => val1, ...}}
      ref = source_obj.keys.first
      source_attrs = source_obj.values.first

      #cloned object source object type specfic processing
      set_model_specific_override_attrs!(override_attrs,source_attrs,ref)

      #if override_attrs has key :ref then that means to reroot to another ref
      new_ref = override_attrs.delete(:ref)
      if new_ref
        source_obj[new_ref] = source_obj.delete(source_obj.keys.first)
      end
      #subsititue in override attributes
      override_attrs.each {|field,value| source_attrs[field] = value}
    end

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
      dups_allowed_for_cmp = false #TODO stub
      create_opts = {:duplicate_refs => dups_allowed_for_cmp ? :allow : :prune_duplicates, :sync_display_name_with_ref => true}
      create_override_attrs = override_attrs.merge(:ancestor_id => source_id_handle.get_id()) 
      new_ids = create_from_select(target_model_handle,field_set_to_copy,select_ds,create_override_attrs,create_opts)
      return Array.new if new_ids.empty?
      #TODO: iterate overall all children

      new_ids.map{|id|source_id_handle.createIH({:id => id,:parent_model_name => target_parent_model_name})}
    end

    def deprecate_clone_copy(id_handle,source_obj,target_id_handle,opts)
      relation_type = id_handle[:model_name]
#      clone_helper = CloneHelper.new(@db) if no_clone_helper_provided = clone_helper.nil?
      no_clone_helper_provided = true
      clone_helper = CloneHelper.new(@db) 

      tgt_factory_id_handle = get_factory_id_handle(target_id_handle,relation_type)
      raise Error.new("clone target (#{target_id_handle}) not found") if tgt_factory_id_handle.nil?

      create_opts = opts.merge({:shift_id_to_ancestor => true,:sync_display_name_with_ref => true})
      new_item = create_from_hash(tgt_factory_id_handle,source_obj, clone_helper, create_opts).first
      clone_helper.set_foreign_keys_to_right_values() if no_clone_helper_provided

      IDHandle[:c => id_handle[:c], :id => new_item[:id], :model_name => id_handle[:model_name]]
    end
  end
end
