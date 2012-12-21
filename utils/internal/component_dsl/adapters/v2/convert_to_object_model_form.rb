module DTK; class ComponentDSL; class V2
  class ObjectModelForm < ComponentDSL::ObjectModelForm
    def self.convert(input_hash)
      new.convert(input_hash)
    end
    def convert(input_hash)
      Component.new(input_hash.req(:module_name)).convert(input_hash.req(:components))
    end
    class Component < self
      def initialize(module_name)
        @module_name = module_name
      end
      def convert(input_hash)
        input_hash
      end
    end
  end
end; end; end
=begin
{"components"=>
  {"sink"=>
    {"attributes"=>
      {"members"=>
        {"type"=>"array(string)",
         "description"=>"Members gotten from connected sources"}},
     "external_ref"=>{"puppet_class"=>"v2::sink"}},
   "source"=>
    {"link_defs"=>
      {"member"=>
        {"possible_links"=>
          [{"v2::sink"=>
             {"attribute_mappings"=>
               [{"local_node.host_addresses_ipv4.0"=>"v2::sink.members"}]}}],
         "type"=>"external"}},
     "external_ref"=>{"puppet_class"=>"v2::source"}}},
 "module_type"=>"puppet_module",
 "version"=>"0.9",
 "module_name"=>"v2"}
=end
