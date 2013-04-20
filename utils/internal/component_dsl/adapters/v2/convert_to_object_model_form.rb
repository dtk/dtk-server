#TODO: this does some conversion of form; should determine what shoudl be done here versus subsequent parser phase
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
        add_dependent_components!(ret,input_hash,cmp_type)
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
        external_ref["type"] != "puppet_definition"
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

      #partitions into link_defs, "dependency", and "component_order"
      def add_dependent_components!(ret,input_hash,base_cmp)
        dep_config = get_dependent_config(input_hash,base_cmp)
        ret.set_if_not_nil("dependency",dep_config[:dependencies])
        ret.set_if_not_nil("component_order",dep_config[:component_order])
        ret.set_if_not_nil("link_defs",dep_config[:link_defs])
      end

      def get_dependent_config(input_hash,base_cmp)
        ret = Hash.new
        if links = input_hash["depends_on"]
          lds = ret[:link_defs] = Array.new
          links.each_pair do |ld_ref,in_link_def|
            dep_cmp = convert_to_internal_cmp_form(ld_ref)
            ld_type = in_link_def["relation_type"]||component_part(dep_cmp)
            ld = OutputHash.new("type" => ld_type)
            link_type = link_type(in_link_def)

            is_required = ld["required"] = is_required?(in_link_def)
            if is_required
              if link_type == "internal"
                pntr = ret[:dependencies] ||= OutputHash.new
                add_dependency!(pntr,dep_cmp,base_cmp)
              end
            end
            possible_links = ld["possible_links"] = Array.new
            if in_attr_mappings = in_link_def["attribute_mappings"]
              ams = in_attr_mappings.map{|in_am|convert_attribute_mapping(in_am,base_cmp,dep_cmp)}
              possible_link = OutputHash.new(convert_to_internal_cmp_form(dep_cmp) => {"type" => link_type,"attribute_mappings" => ams})
              possible_links << possible_link
            end
=begin
 put back in when processing choices            
            in_link_def.req(:endpoints).each_pair do |pl_cmp,in_pl_info|
              ams = in_pl_info.req(:attribute_mappings).map{|in_am|convert_attribute_mapping(in_am)}
              possible_link = OutputHash.new(convert_to_internal_cmp_form(pl_cmp) => {"type" => link_type(in_pl_info),"attribute_mappings" => ams})
              possible_links << possible_link
            end
=end
            lds << ld
          end
        end
        ret[:component_order] = component_order(input_hash)
        ret
      end

      def add_dependency!(ret,dep_cmp,base_cmp)
        ret[dep_cmp] ||= { 
          "type"=>"component",
          "search_pattern"=>{":filter"=>[":eq", ":component_type", dep_cmp]},
          "description"=>
          "#{convert_to_pp_cmp_form(dep_cmp)} is required for #{convert_to_pp_cmp_form(base_cmp)}",
          "display_name"=>dep_cmp,
          "severity"=>"warning"
        }
      end

      def component_order(input_hash)
        if after_cmps = input_hash["after"]
          after_cmps.inject(OutputHash.new) do |h,after_cmp|
            after_cmp_internal_form = convert_to_internal_cmp_form(after_cmp)
            el={after_cmp_internal_form =>
              {"after"=>after_cmp_internal_form}}
            h.merge(el)
          end
        end
      end

      def component_part(cmp)
        if cmp =~ Regexp.new("^.+#{ModCmpDelim}(.+$)")
          $1
        else
          cmp
        end
      end

      DefaultLinkType = "local"
      def link_type(link_info)
        ret = 
          if loc = link_info["location"]||DefaultLinkType
            case loc
              when "local" then "internal"
              when "remote" then "external"
            else 
              raise ParsingError.new("Ill-formed dependency location type (?1)",loc)
            end
          end
        ret||"external"
      end

      DefaultIsRequired = true
      def is_required?(link_info)
        link_info["required"]||DefaultIsRequired
      end

      def convert_attribute_mapping(input_am,base_cmp,this_cmp)
        if input_am =~ /(^[^ ]+)[ ]*->[ ]*([^ ]+$)/
          output = convert_attr_ref($1,base_cmp,this_cmp)
          input = convert_attr_ref($2,base_cmp,this_cmp)
          output.gsub!(/host_address$/,"host_addresses_ipv4.0")
          {output => input}
        else
          raise ParsingError.new("Attribute mapping (?1) is ill-formed",input_am)
        end
      end

      def convert_attr_ref(attr_ref,base_cmp,dep_cmp)
        ret = 
          if attr_ref =~ /(^[^.]+)\.([^.]+$)/
            cmp_or_node_ref = $1
            attr = $2
            case cmp_or_node_ref
              when "base" then convert_to_internal_cmp_form(base_cmp)
              when "node" then "remote_node"
              when "base_node" then "local_node"
            end + ".#{attr}"
          else
            "#{convert_to_internal_cmp_form(dep_cmp)}.#{attr_ref}"
          end
        unless ret
          raise ParsingError.new("Attribute reference (?1) is ill-formed",attr_ref)
        end
        ret
      end

      CmpPPDelim = '::'
      def convert_to_internal_cmp_form(cmp)
        cmp.gsub(Regexp.new(CmpPPDelim),ModCmpDelim)
      end
      def convert_to_pp_cmp_form(cmp)
        cmp.gsub(Regexp.new(ModCmpDelim),CmpPPDelim)
      end
    end
  end
end; end; end

