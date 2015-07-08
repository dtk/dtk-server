module XYZ
  module DSConnector
    class UserData < Top
      def initialize_extra
        @user_data_cache = Aux::Cache.new
      end

      def get_objects__node(&block)
        get_user_data_objects(:node,&block)
      end

      def get_objects__component(&block)
        get_user_data_objects(:component,&block)
      end

      private

      def get_user_data_objects(type,&block)
        data_file_path = R8::Config[:app_cache_root] + "/data_source.json" #TODO: stub
        # no op if file does not exists
        hash_all_data = get_user_data_from_file(data_file_path)
        return HashMayNotBeComplete.new() unless hash_all_data

        # find contents under container uri
        hash = HashObject.nested_value(hash_all_data,nested_path(hash_all_data))
        return HashMayNotBeComplete.new() unless hash

        (hash[type.to_s]||{}).each do |ref,info|
          qualified_ref = "#{@container_uri}/#{ref}"
          block.call(DataSourceUpdateHash.new(info.merge({"ref" => ref,"qualified_ref" => qualified_ref})))
        end
        # HashMayNotBeComplete.new() TODO: so can prune what is included
        HashIsComplete.new()
      end

      def get_user_data_from_file(data_file_path)
        @user_data_cache[:all] ||= Aux::hash_from_file_with_json(data_file_path)
      end

      def nested_path(_hash_all_data)
        @container_uri.gsub(Regexp.new("^/"),"").split("/")
      end
    end
  end
end
