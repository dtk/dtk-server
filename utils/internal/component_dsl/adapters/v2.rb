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
        new_version = version()
        MigrateProcessor.new(new_version,config_agent_type,module_name,old_version_hash)
      end
    end
  end
end
=begin

example translations 

normalized form
{"dtk_server__base"=>{"display_name"=>"dtk_server__base",
  "description"=>"DTK Server",
  "external_ref"=>{"class_name"=>"dtk_server::base", "type"=>"puppet_class"},
  "basic_type"=>"service",
  "component_type"=>"dtk_server__base",
  "dependency"=>{"gitolite"=>
    {"type"=>"component",
     "search_pattern"=>{":filter"=>[":eq", ":component_type", "gitolite"]},
     "description"=>"gitolite is required for dtk_server__base",
     "display_name"=>"gitolite",
     "severity"=>"warning"},
   "dtk"=>
    {"type"=>"component",
     "search_pattern"=>{":filter"=>[":eq", ":component_type", "dtk"]},
     "description"=>"dtk is required for dtk_server__base",
     "display_name"=>"dtk",
     "severity"=>"warning"}}},
 "dtk_server__tenant"=>{"display_name"=>"dtk_server__tenant",
  "description"=>"DTK Server",
  "external_ref"=>{"definition_name"=>"dtk_server::tenant",
   "type"=>"puppet_definition"},
  "basic_type"=>"service",
  "component_type"=>"dtk_server__tenant",
  "only_one_per_node"=>false,
  "attribute"=>{"server_git_branch"=>{"display_name"=>"server_git_branch",
    "description"=>"Branch in server git repo to use",
    "data_type"=>"string",
    "external_ref"=>{"type"=>"puppet_attribute",
     "path"=>"node[dtk_server__tenant][server_git_branch]"}},
   "name"=>{"display_name"=>"name",
    "description"=>"User name",
    "data_type"=>"string",
    "required"=>true,
    "external_ref"=>{"type"=>"puppet_attribute",
     "path"=>"node[dtk_server__tenant][name]"}},
   "stomp_server_host"=>{"display_name"=>"stomp_server_host",
    "description"=>"Stomp server host",
    "data_type"=>"string",
    "external_ref"=>{"type"=>"puppet_attribute",
     "path"=>"node[dtk_server__tenant][stomp_server_host]"}},
   "server_public_dns"=>{"display_name"=>"server_public_dns",
    "description"=>"Server public dns",
    "data_type"=>"string",
    "external_ref"=>{"type"=>"puppet_attribute",
     "path"=>"node[dtk_server__tenant][server_public_dns]"}},
   "db_host"=>{"display_name"=>"db_host",
    "description"=>"Database server host",
    "data_type"=>"string",
    "external_ref"=>{"type"=>"puppet_attribute",
     "path"=>"node[dtk_server__tenant][db_host]"}},
   "port"=>{"display_name"=>"port",
    "description"=>"port that server runs on",
    "data_type"=>"integer",
    "external_ref"=>{"type"=>"puppet_attribute",
     "path"=>"node[dtk_server__tenant][port]"}},
   "gitolite_user"=>{"display_name"=>"gitolite_user",
    "description"=>"User name for gitolite server",
    "data_type"=>"string",
    "required"=>true,
    "external_ref"=>{"type"=>"puppet_attribute",
     "path"=>"node[dtk_server__tenant][gitolite_user]"}}},
  "dependency"=>{"dtk_server__base"=>
    {"type"=>"component",
     "search_pattern"=>
      {":filter"=>[":eq", ":component_type", "dtk_server__base"]},
     "description"=>"dtk_server__base is required for dtk_server__tenant",
     "display_name"=>"dtk_server__base",
     "severity"=>"warning"}},
  "component_order"=>{"dtk_postgresql__db"=>{"after"=>"dtk_postgresql__db"}},
  "external_link_defs"=>[{"required"=>false,
    "possible_links"=>
     [{"dtk_activemq"=>
        {"attribute_mappings"=>
          [{":remote_node.host_addresses_ipv4.0"=>
             ":dtk_server__tenant.stomp_server_host"}]}}],
    "type"=>"stomp-server"},
   {"required"=>false,
    "possible_links"=>
     [{"dtk_postgresql__server"=>
        {"attribute_mappings"=>
          [{":remote_node.host_addresses_ipv4.0"=>
             ":dtk_server__tenant.db_host"}]}}],
    "type"=>"db"}]}}

----

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
