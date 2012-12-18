module DTK
  class ComponentDSL
    class V2 < self
      r8_nested_require('v2','migrate_processor')
      def self.parse_check(input_hash)
        #TODO: stub
      end
      def self.normalize(input_hash)
        input_hash
      end
      def self.ret_migrate_processor(module_name,old_version_hash)
        MigrateProcessor.new(module_name,self,old_version_hash)
      end
    end
  end
end
