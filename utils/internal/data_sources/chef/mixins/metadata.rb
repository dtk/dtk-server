module XYZ
  module DSConnector
   module ChefMixinMetadata # TODO: unify with code in R8Cookbook
     SpecialMetaAttribute = "_meta_info"
     SpecialMetaFields = %w{basic_types}
     def process_raw_metadata!(metadata)
       special = (metadata["attributes"]||{})[SpecialMetaAttribute]
       return metadata unless special
       SpecialMetaFields.each{|f|metadata[f] = special[f]}
       metadata["attributes"].delete(SpecialMetaAttribute)
       metadata
     end

     def get_component_services_info(recipe_name,cookbook_meta)
       ret = ArrayObject.new
       return ret unless cookbook_meta
       cookbook_name = recipe_name.gsub(/::.+/,"")
       meta = (eval($1) if cookbook_meta["long_description"] =~ /__(.+)__/m) #/m because there may be internal line breaks
       (meta||[]).each do |meta_service_info|
         base_info = get_service_info(recipe_name,meta_service_info)
         next if base_info.empty?
         cookbook_meta["attributes"].each do |attr,info|
           set_attribute_info(base_info,attr,info,cookbook_name,recipe_name,meta_service_info[:service_name])
         end
         ret << base_info.freeze
       end
        ret
     end

     def get_service_info(recipe_name,meta_service_info)
       ret = HashObject::AutoViv.create()
       if (meta_service_info[:recipe_names]||[]).include?(recipe_name)
         # TBD: modify use of canonical_service_name
         ret[:canonical_service_name] = meta_service_info[:service_name]
         ret[:conditions] = meta_service_info[:conditions]
       end
       ret
     end

     private

     # returns [(normalized)attr_name,service_name]
     def get_attribute_and_service_names(attr_name)
       if attr_name =~ Regexp.new("^(.+)/_service/(.+?)/(.+)$")
         ["#{$1}/#{$3}",$2]
       else
         [attr_name,nil]
       end
     end

     def set_attribute_info(target,attr,attr_info,cookbook_name,recipe_name,service_name)
       return nil unless attr_info["is_service_attribute"]
       transform = attr_info["transform"]
       return nil unless transform
       return nil unless attr_info["recipes"].empty? || attr_info["recipes"].include?(recipe_name)
       if attr =~ Regexp.new("#{cookbook_name}/_service/#{service_name}/(.+)$")
         key = $1
         set_attribute_transform_info(target["params"],key,transform)
       end
     end

     def ret_normalized_transform_info(transform)
       ret = HashObject::AutoViv.create()
       set_attribute_transform_info(ret,0,transform)
       ret.freeze
       ret[0]
     end

     def set_attribute_transform_info(target,key,transform)
       if transform.is_a?(Hash)
         if transform.keys.include?("__ref")
           target[key]["external_ref"]["type"] = "chef_attribute"
           target[key]["external_ref"]["ref"] = transform.values.first
         else
           transform.each{|k,v|set_attribute_transform_info(target[key],k,v)}
         end
       elsif transform.is_a?(Array)
         target[key] = transform.map do |child|
           if child.is_a?(Hash)
             child_target = HashObject::AutoViv.create()
             child.each{|k,v|set_attribute_transform_info(child_target,k,v)}
             child_target
           else
             child
           end
         end
       else
         target[key] = transform
       end
     end
   end
 end
end
