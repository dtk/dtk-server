module XYZ
  module CloneClassMixins

    def clone(id_handle,target_id_handle,override_attrs={}, opts={})
      copy_target_id_handle = ret_copy_target_id_handle(id_handle,target_id_handle)
      new_id_handle = clone_copy(id_handle,copy_target_id_handle,override_attrs,opts)
      #calling with respect to target
      model_class(target_id_handle[:model_name]).clone_post_copy_hook(new_id_handle,target_id_handle,copy_target_id_handle)
      return new_id_handle.get_id()
    end

   protected
    #ovreride to handle case where actual copy target diffeernt from target specfied in clone operation
    def ret_copy_target_id_handle(id_handle,target_id_handle)
      target_id_handle
    end

    # to be overwritten by object representing the target
    def clone_post_copy_hook(new_id_handle,target_id_handle,copy_target_id_handle)
    end

    #copy part of clone
    def clone_copy(id_handle,target_id_handle,override_attrs={}, opts={})
      relation_type = id_handle[:model_name]
#      clone_helper = CloneHelper.new(@db) if no_clone_helper_provided = clone_helper.nil?
      no_clone_helper_provided = true
      clone_helper = CloneHelper.new(@db) 
      obj = get_instance_or_factory(id_handle,nil,{:depth => :deep, :no_hrefs => true})
      raise Error.new("clone source (#{id_handle}) not found") if obj.nil? 

#TODO: cleanup, why are objects indexed with a top level key that is the name?
      obj.each do |key,obj_value|
        override_attrs.each {|field,value| obj[key][field] = value}
      end

      tgt_factory_id_handle = get_factory_id_handle(target_id_handle,relation_type)
      raise Error.new("clone target (#{target_id_handle}) not found") if tgt_factory_id_handle.nil?

      new_uri = create_from_hash(tgt_factory_id_handle,obj, clone_helper,opts.merge({:shift_id_to_ancestor => true})).first
      clone_helper.set_foreign_keys_to_right_values() if no_clone_helper_provided

      new_id_handle = IDHandle[:c => id_handle[:c], :uri => new_uri, :model_name => id_handle[:model_name]]
      Log.info("created new object with uri #{new_uri} and id #{new_id_handle.get_id()}") 
      new_id_handle
    end
  end
end
