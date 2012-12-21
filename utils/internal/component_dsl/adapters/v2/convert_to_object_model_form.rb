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
        input_hash.inject(OutputHash.new){|h,(k,v)|h.merge(key(k) => body(v,k))}
      end
     private
      def key(input_key)
        "#{@module_name}__#{input_key}"
      end
      
      def body(input_hash,cmp)
        ret = OutputHash.new
        ret["external_ref"] = external_ref(input_hash.req(:external_ref),cmp)
        ret
      end

      def external_ref(input_hash,cmp)
        unless input_hash.kind_of?(Hash) and input_hash.size == 1
          raise ParsingError.new("Component (?1) external_ref is ill-formed (?2)",cmp,input_hash)
        end
        type = input_hash.keys.first
        name_key = 
          case type 
            when "puppet_class" then "class_name" 
            when "puppet_defition" then "definition_name" 
          else raise ParsingError.new("Component (?1) external_ref has illegal type (?2)",cmp,type)
          end
        name = input_hash.values.first
        OutputHash.new("type" => type,name_key => name)
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
