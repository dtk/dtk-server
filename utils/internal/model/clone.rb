module XYZ
  module CloneClassMixins
    def clone(id_handle,target_id_handle,opts={})
      relation_type = id_handle[:model_name]
#      clone_helper = CloneHelper.new(@db) if no_clone_helper_provided = clone_helper.nil?
      no_clone_helper_provided = true
      clone_helper = CloneHelper.new(@db) 
      obj = get_instance_or_factory(id_handle,nil,{:depth => :deep, :no_hrefs => true})
      raise Error.new("clone source (#{id_handle}) not found") if obj.nil? 

      tgt_factory_id_handle = get_factory_id_handle(target_id_handle,relation_type)
      raise Error.new("clone target (#{target_id_handle}) not found") if tgt_factory_id_handle.nil?

      new_uris = create_from_hash(tgt_factory_id_handle,obj, clone_helper,opts.merge({:shift_id_to_ancestor => true}))
      clone_helper.set_foreign_keys_to_right_values() if no_clone_helper_provided

      new_uris
    end
  end
end
