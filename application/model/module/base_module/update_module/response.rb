module DTK; class BaseModule; class UpdateModule
  class Response < Hash
    def initialize(hash={})
      super()
      replace(hash)
    end
    OutputForImportKeys = {
      :dsl_parse_error       => true,
      :dsl_updated_info      => [:commit_sha], 
      :dsl_created_info      => [:path,:content],
      :external_dependencies => [:inconsistent,:possibly_missing,:ambiguous]
    }

    def output_for_import()
      relevant_keys(OutputForImportKeys)
    end

   private
    def relevant_keys(key_info)
      ret = Response.new()
      key_info.each_pair do |top_key,nested_info|
        if has_key?(top_key)
          v = self[top_key]
          if nested_info.kind_of?(Array) 
            info = Aux::hash_subset(v,nested_keys)
            ret[top_key] = info unless info.empty?
          else
            ret[top_key] = v
          end
        end
      end
    end
  end
end; end; end
