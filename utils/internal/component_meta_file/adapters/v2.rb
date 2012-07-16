module DTK
  class ComponentMetaFileV2 < ComponentMetaFile
    def self.parse_check(input_hash)
      #TODO: stub
    end
    def self.normalize(input_hash)
      input_hash
    end
    def self.ret_migrate_processor(old_version_hash)
      MigrateProcessor.new(old_version_hash)
    end
    class MigrateProcessor < SimpleOrderedHash
    end
  end
end
