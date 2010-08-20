module XYZ
  module DSConnector
   module ChefMixinMetadata # TODO unify with code in R8Cookbook
     def get_component_services_info(recipe_name)
       ret = ArrayObject.new
       cookbook_name = recipe_name.gsub(/::.+/,"")
       cookbook_meta = get_metadata(cookbook_name)
       return ret unless cookbook_meta
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
       ret = HashObject.create_with_auto_vivification()
       if (meta_service_info[:recipe_names]||[]).include?(recipe_name)
         #TBD: modify use of canonical_service_name
         ret[:canonical_service_name] = meta_service_info[:service_name]
         ret[:conditions] = meta_service_info[:conditions]
       end
       ret
     end

     private
     def set_attribute_info(target,attr,attr_info,cookbook_name,recipe_name,service_name) 
       return nil unless attr_info["is_service_attribute"]
       transform = attr_info["transform"]
       return nil unless transform
       return nil unless attr_info["recipes"].empty? or attr_info["recipes"].include?(recipe_name)
       if attr =~ Regexp.new("#{cookbook_name}/_service/#{service_name}/(.+)$")
         key = $1
         set_attribute_transform_info(target["params"],key,transform)
       end
     end

     def set_attribute_transform_info(target,key,transform)
       if transform.kind_of?(Hash)
         if transform.keys.include?("__ref")
           target[key]["external_ref"]["type"] = "chef_attribute"
           target[key]["external_ref"]["ref"] = transform.values.first
         else
           transform.each{|k,v|set_attribute_transform_info(target[key],k,v)}
         end
       elsif transform.kind_of?(Array)
         target[key] = transform.map do |child|
           if child.kind_of?(Hash) 
             child_target = HashObject.create_with_auto_vivification()
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



