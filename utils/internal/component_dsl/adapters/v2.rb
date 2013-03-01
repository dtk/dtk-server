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
pp [:input_hash,input_hash]
        ret = ObjectModelForm.convert(ObjectModelForm::InputHash.new(input_hash))
pp [:normalize,ret]
ret
      end

      def self.ret_migrate_processor(config_agent_type,module_name,old_version_hash)
        new_version = version()
        MigrateProcessor.new(new_version,config_agent_type,module_name,old_version_hash)
      end
    end
  end
end
=begin
example tarnslation 
From
[:input_hash,
 {"components"=>
   {"sink"=>
     {"attributes"=>
       {"param1"=>{"type"=>"string", "description"=>"Param1"},
        "members"=>
         {"type"=>"array(string)",
          "description"=>"Members gotten from connected sources"}},
      "external_ref"=>{"puppet_class"=>"temp::sink"}},
    "source"=>
     {"link_defs"=>
       {"member"=>
         {"possible_links"=>
           [{"temp::sink"=>
              {"attribute_mappings"=>
                [{"local_node.host_addresses_ipv4.0"=>
                   "temp::sink.members"}]}}],
          "type"=>"external"}},
      "attributes"=>{"param2"=>{"type"=>"string", "description"=>"Param2"}},
      "external_ref"=>{"puppet_class"=>"temp::source"}}},
  "module_type"=>"puppet_module",
  "version"=>"0.9",
  "module_name"=>"temp"}]

To
{"temp__source"=>
  {"basic_type"=>"service",
   "external_link_defs"=>
    [{"possible_links"=>
       [{"temp__sink"=>
          {"attribute_mappings"=>
            [{":local_node.host_addresses_ipv4.0"=>":temp__sink.members"}]}}],
      "type"=>"member"}],
   "attribute"=>
    {"param2"=>
      {"data_type"=>"string",
       "description"=>"Param2",
       "display_name"=>"param2",
       "external_ref"=>
        {"type"=>"puppet_attribute", "path"=>"node[temp][param2]"}}},
   "display_name"=>"temp__source",
   "external_ref"=>{"class_name"=>"temp::source", "type"=>"puppet_class"},
   "component_type"=>"temp__source"},
 "temp__sink"=>
  {"basic_type"=>"service",
   "attribute"=>
    {"param1"=>
      {"data_type"=>"string",
       "description"=>"Param1",
       "display_name"=>"param1",
       "external_ref"=>
        {"type"=>"puppet_attribute", "path"=>"node[temp][param1]"}},
     "members"=>
      {"required"=>true,
       "data_type"=>"json",
       "semantic_type_summary"=>"array(string)",
       "description"=>"Members gotten from connected sources",
       "display_name"=>"members",
       "external_ref"=>
        {"type"=>"puppet_attribute", "path"=>"node[temp][members]"},
       "semantic_type"=>{":array"=>"string"}}},
   "display_name"=>"temp__sink",
   "external_ref"=>{"class_name"=>"temp::sink", "type"=>"puppet_class"},
   "component_type"=>"temp__sink"}}
=end
