module DTK
  class ComponentDSL
    class V2 < self
      r8_nested_require('v2','migrate_processor')
      r8_nested_require('v2','parser')
      r8_nested_require('v2','dsl_object')
      r8_nested_require('v2','convert_to_object_model_form')
      def self.parse_check(input_hash)
        #TODO: stub
      end
      def self.normalize(input_hash)
        ObjectModelForm.convert(ObjectModelForm::InputHash.new(input_hash))
      end

      def self.ret_migrate_processor(config_agent_type,module_name,old_version_hash)
        new_version = version(2)
        MigrateProcessor.new(new_version,config_agent_type,module_name,old_version_hash)
      end
    end
  end
end
