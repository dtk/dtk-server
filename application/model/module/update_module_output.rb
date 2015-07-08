module DTK
  class UpdateModuleOutput < Hash
    def initialize(hash={})
      super()
      return if hash.empty?
      pruned_hash = ret_relevant_keys(hash)
      replace(pruned_hash)
    end
    # create_info is aligned with this object on keys; it just has more info
    def self.create_from_update_create_info(create_info)
      new(create_info)
    end
    LegalKeysInfo = {
      dsl_parse_error: true,
      dsl_updated_info: [:commit_sha,:msg],
      dsl_created_info: [:path,:content],
      external_dependencies: [:inconsistent,:possibly_missing,:ambiguous]
    }
    LegalTopKeys = LegalKeysInfo.keys

    def set_dsl_updated_info!(msg,commit_sha)
      ret = self[:dsl_updated_info] ||= {}
      ret.merge!(msg: msg) unless msg.nil?
      ret.merge!(commit_sha: commit_sha) unless commit_sha.nil?
      ret
    end

    def external_dependencies
      ExternalDependencies.new(self[:external_dependencies]||{})
    end

    def dsl_created_info?
      info = self[:dsl_created_info]
      unless info.nil? || info.empty?
        DSLCreatedInfo.new(info)
      end
    end
    class DSLCreatedInfo < Hash
      def initialize(hash)
        super()
        replace(hash)
      end
    end

    private

    def ret_relevant_keys(hash)
      ret = {}
      LegalKeysInfo.each_pair do |top_key,nested_info|
        if hash.key?(top_key)
          nested = hash[top_key]
          if nested_info.is_a?(Array) && nested.is_a?(Hash)
            legal_nested_keys = nested_info
            info = Aux::hash_subset(nested,legal_nested_keys)
            ret[top_key] = info unless info.empty?
          else
            ret[top_key] = nested
          end
        end
      end
      ret
    end
  end
end
