module DTK; class BaseModule; module UpdateModule
  class Response < Hash
    OutputForImportKeys = {
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
      key_info.each_pair do |top_key,nested_keys|
        if v = self[top_key]
          info = Aux::hash_subset(v,nested_keys)
          ret[top_key] = info unless info.empty?
        end
      end
    end
  end
end; end; end
