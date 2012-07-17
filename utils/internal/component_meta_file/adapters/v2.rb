module DTK
  class ComponentMetaFileV2 < ComponentMetaFile
    r8_nested_require('v2','migrate_processor')
    def self.parse_check(input_hash)
      #TODO: stub
    end
    def self.normalize(input_hash)
      input_hash
    end
    def self.ret_migrate_processor(old_version_hash)
      MigrateProcessor.new(self,old_version_hash)
    end
  end
end
