#TODO: this does some conversion of form; should determine what shoudl be done here versus subsequent parser phase
module DTK; class ComponentDSL; class V2
  class ObjectModelForm < ComponentDSL::ObjectModelForm
    def self.convert(input_hash)
      new.convert(input_hash)
    end
    def convert(input_hash)
      Component.new(input_hash.req(:module)).convert(input_hash.req(:components))
    end

    def convert_to_hash_form(hash_or_array,&block)
      if hash_or_array.kind_of?(Hash)
        hash_or_array.each_pair{|k,v|block.call(k,v)}
      else #hash_or_array.kind_of?(Array)
        hash_or_array.each do |el|
          if el.kind_of?(Hash)
            block.call(el.keys.first,el.values.first)
          else #el.kind_of?(String)
            block.call(el,Hash.new)
          end
        end
      end
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
        opts = Hash.new
        add_dependent_components!(ret,input_hash,cmp_type,opts)
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
            attr_props["value_asserted"] = info["default"] #setting even when info["default"] so this can handle case where remove a default
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
      def add_dependent_components!(ret,input_hash,base_cmp,opts={})
        dep_config = get_dependent_config(input_hash,base_cmp,opts)
        ret.set_if_not_nil("dependency",dep_config[:dependencies])
        ret.set_if_not_nil("component_order",dep_config[:component_order])
        ret.set_if_not_nil("link_defs",dep_config[:link_defs])
      end

      def get_dependent_config(input_hash,base_cmp,opts={})
        ret = Hash.new
        link_defs  = Array.new
        if dep_cmps = input_hash["depends_on"]
          convert_to_hash_form(dep_cmps) do |in_dep_cmp_ref,in_dep_cmp|
            dep_cmp = convert_to_internal_cmp_form(in_dep_cmp_ref)
            ld_type = in_dep_cmp["relation_name"]||component_part(dep_cmp)
            ld = OutputHash.new("type" => ld_type)
            link_type = link_type(in_dep_cmp)

            is_required = ld["required"] = is_required?(in_dep_cmp)
            if is_required
              if link_type == "internal"
                pntr = ret[:dependencies] ||= OutputHash.new
                add_dependency!(pntr,dep_cmp,base_cmp)
              end
            end
            possible_links = ld["possible_links"] = Array.new
            if in_attr_mappings = in_dep_cmp["attribute_mappings"]
              ams = in_attr_mappings.map{|in_am|convert_attribute_mapping(in_am,base_cmp,dep_cmp,opts)}
              possible_link = OutputHash.new(convert_to_internal_cmp_form(dep_cmp) => {"type" => link_type,"attribute_mappings" => ams})
              possible_links << possible_link
              link_defs << ld
            end
          end
        end
        ret[:link_defs] = link_defs unless link_defs.empty?
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
        link_info["required"].nil? ? DefaultIsRequired : link_info["required"]
      end

      def convert_attribute_mapping(input_am,base_cmp,dep_cmp,opts={})
        #TODO: right now only treating constant on right hand side meaning only for <- case
        if input_am =~ /(^[^ ]+)[ ]*->[ ]*([^ ]+$)/
          dep_attr,base_attr = [$1,$2]
          left = convert_attr_ref_simple(dep_attr,:dep,dep_cmp)
          right = convert_attr_ref_simple(base_attr,:base,base_cmp)
        elsif input_am =~ /(^[^ ]+)[ ]*<-[ ]*([^ ]+$)/
          dep_attr,base_attr = [$1,$2]
          left = convert_attr_ref_base(base_attr,base_cmp,dep_attr,dep_cmp,opts)
          right = convert_attr_ref_simple(dep_attr,:dep,dep_cmp)
        else
          raise ParsingError.new("Attribute mapping (?1) is ill-formed",input_am)
        end
        {left => right}
      end

      def convert_attr_ref_simple(attr_ref,dep_or_base,cmp)
        if attr_ref =~ /(^[^.]+)\.([^.]+$)/
          prefix = $1
          attr = $2
          case prefix
            when "node" then (dep_or_base == :dep) ? "remote_node" : "local_node"
            else raise ParsingError.new("Attribute reference (?1) is ill-formed",attr_ref)  
          end + ".#{attr.gsub(/host_address$/,"host_addresses_ipv4.0")}"
        else
          "#{convert_to_internal_cmp_form(cmp)}.#{attr_ref}"
        end
      end

      def convert_attr_ref_base(attr_ref,base_cmp,dep_attr_ref,dep_cmp,opts={})
        if attr_ref =~ /(^[^.]+)\.([^.]+$)/
          prefix = $1
          attr = $2
          case prefix
            when "node" then "local_node"
            else raise ParsingError.new("Attribute reference (?1) is ill-formed",attr_ref)  
          end + ".#{attr.gsub(/host_address$/,"host_addresses_ipv4.0")}"
        else
          stripped_attr_ref = ConstantAssignment.strip_constant?(attr_ref,dep_attr_ref,dep_cmp,opts)
          "#{convert_to_internal_cmp_form(base_cmp)}.#{stripped_attr_ref}"
        end
      end

      class ConstantAssignment 
        def initialize(constant,dep_attr_ref,dep_cmp)
          @dependent_attribute = dep_attr_ref
          @dependent_component = dep_cmp
          @constant = constant
        end
        def self.strip_constant?(attr_ref,dep_attr_ref,dep_cmp,opts={})
          ret = attr_ref
          if attr_ref = /^constant\:(.+$)/
            stripped_attr_ref = $1
            constant_assign = new(stripped_attr_ref,dep_attr_ref,dep_cmp)
            (opts[:constants] ||= Array.new) << constant_assign
            ret = constant_assign.attribute_name()
          end
          ret
        end

        ConstantDelim = "___"
        def attribute_name()
          "#{ConstantDelim}constant#{ConstantDelim}#{@dependent_component}#{ConstantDelim}#{@dependent_attribute}"
        end
        def attribute_value()
          @constant
        end
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

