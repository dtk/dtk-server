#TODO: this does some conversion of form; should determine what shoudl be done here versus subsequent phase
module DTK; class ComponentDSL; class V2
  class ObjectModelForm < ComponentDSL::ObjectModelForm
    def self.convert(input_hash)
      new.convert(input_hash)
    end
    def convert(input_hash)
      Component.new(input_hash.req(:module)).convert(input_hash.req(:components))
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
         qualified_component(input_key)
      end
      def qualified_component(cmp)
        if @module_name == cmp
          cmp
        else
          "#{@module_name}#{ModCmpDelim}#{cmp}"
        end
      end

      ModCmpDelim = "__"
      
      def body(input_hash,cmp)
        ret = OutputHash.new
        cmp_type = ret["display_name"] = ret["component_type"] = qualified_component(cmp)
        ret["basic_type"] = "service"
        ret.set_if_not_nil("description",input_hash["description"])
        external_ref = external_ref(input_hash.req(:external_ref),cmp)
        ret["external_ref"] = external_ref
        ret.set_if_not_nil("only_one_per_node",only_one_per_node(external_ref))
        add_attributes!(ret,cmp_type,input_hash)
        add_link_defs!(ret,input_hash)
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
            when "puppet_definition" then "definition_name" 
          else raise ParsingError.new("Component (?1) external_ref has illegal type (?2)",cmp,type)
          end
        name = input_hash.values.first
        OutputHash.new("type" => type,name_key => name)
      end

      def only_one_per_node(external_ref)
        external_ref["type"] == "puppet_definition" ? true : nil
      end
      
      def add_attributes!(ret,cmp_type,input_hash)
        if in_attrs = input_hash["attributes"]
          attrs = OutputHash.new
          in_attrs.each_pair do |name,info|
            attr_props = OutputHash.new(
              "display_name" => name,
              "external_ref" => {
                 "type" => "puppet_attribute", #TODO: hard-wired
                 "path" => "node[#{cmp_type}][#{name}]"
              }
            )
            add_attr_data_type_attrs!(attr_props,info)
            attr_props.set_if_not_nil("value_asserted",info["default"])
            attr_props.set_if_not_nil("description",info["description"])
            attr_props.set_if_not_nil("required",info["required"])
            attrs.merge!(name => attr_props)
          end
          ret.merge!("attribute" => attrs)
        end
        ret
      end

      def add_attr_data_type_attrs!(attr_props,info)
        type = info.req(:type)
        if AutomicTypes.include?(type)
          attr_props.merge!("data_type" => type)
        elsif type =~ /^array\((.+)\)$/
          scalar_type = $1
          if ScalarTypes.include?(scalar_type)
            semantic_type = {":array" => scalar_type} 
            attr_props.merge!("data_type" => "json","semantic_type_summary" => type,"semantic_type" => semantic_type)
          end
        end
        unless attr_props["data_type"]
          raise ParsingError.new("Ill-formed attribute data type (?1)",type)
        end
        attr_props
      end
      ScalarTypes = %w{integer string boolean}
      AutomicTypes = ScalarTypes + %w{json}

      def add_link_defs!(ret,input_hash)
        if input_hash["links"]
          lds = ret["link_defs"] = Array.new
          input_hash["links"].each_pair do |ld_type,in_link_def|
            ld = OutputHash.new("type" => ld_type)
            ld["required"] = true if in_link_def["required"]
            possible_links = ld["possible_links"] = Array.new
            in_link_def.req(:endpoints).each_pair do |pl_cmp,in_pl_info|
              ams = in_pl_info.req(:attribute_mappings).map{|in_am|convert_attribute_mapping(in_am)}
              possible_link = OutputHash.new(convert_cmp_form(pl_cmp) => {"type" => "external","attribute_mappings" => ams})
              possible_links << possible_link
            end
            lds << ld
          end
        end
        ret
      end

      def convert_attribute_mapping(input_am)
        if input_am =~ /(^[^ ]+)[ ]*->[ ]*([^ ]+$)/
          output = convert_cmp_form($1)
          input = convert_cmp_form($2)
          output.gsub!(/host_address$/,"host_addresses_ipv4.0")
          {output => input}
        else
          raise ParsingError.new("Attribute mapping (?1) is ill-formed",input_am)
        end
      end

      def convert_cmp_form(in_cmp)
        in_cmp.gsub(/::/,ModCmpDelim)
      end

    end
  end
end; end; end

