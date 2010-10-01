module XYZ
  module CloneClassMixins
    def clone(id_handle,target_id_handle,override_attrs={}, opts={})
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

      new_id = IDHandle[:c => id_handle[:c], :uri => new_uri].get_id()
      Log.info("created new object with uri #{new_uri} and id #{new_id}") if new_id
      new_id
    end
  end
end
