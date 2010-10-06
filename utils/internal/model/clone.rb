module XYZ
  module CloneClassMixins

    def clone(id_handle,target_id_handle,override_attrs={},opts={})
      source_obj = opts[:source_obj] || get_object_deep(id_handle)
      raise Error.new("clone source (#{id_handle}) not found") if source_obj.nil? 
      process_override_attributes!(source_obj,override_attrs)
      new_id_handle = clone_copy(id_handle,source_obj,target_id_handle,opts)
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
    def clone_copy(id_handle,source_obj,target_id_handle,opts)
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
