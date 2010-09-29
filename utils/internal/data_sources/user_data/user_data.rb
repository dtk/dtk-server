module XYZ
  module DSConnector
    class UserData < Top
      def get_objects__node(&block)
        data_file_path = R8::Config[:app_cache_root] + "/data_source.json" #TODO: stub
        #no op if file does not exsits
        hash_all_data = Aux::hash_from_file_with_json(data_file_path)
        return HashMayNotBeComplete.new() unless hash_all_data

        #find contents under container uri
        hash = HashObject.nested_value(hash_all_data,nested_path(hash_all_data))
        return HashMayNotBeComplete.new() unless hash

        hash.each do |ref,info|
          qualified_ref = "#{@container_uri}/#{ref}"
          block.call(DataSourceUpdateHash.new(info.merge({"ref" => ref,"qualified_ref" => qualified_ref})))
        end
        HashMayNotBeComplete.new() 
      end
      private
       def nested_path(hash_all_data)
         @container_uri.gsub(Regexp.new("^/"),"").split("/") + ["node"]
       end
    end
  end
end       
