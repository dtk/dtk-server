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
        if opts[:constants]
          add_attributes!(ret,cmp_type,ret_input_hash_with_constants(opts[:constants]),:constant_attribute => true)
        end
        ret
      end

      def ret_input_hash_with_constants(constant_assigns)
        attrs_hash = constant_assigns.inject(InputHash.new) do |h,ca|
          el = {ca.attribute_name() => {
              "type"=>ca.datatype()||"string",
              "default" => ca.attribute_value(),
              #"hidden" => true
            }}
          h.merge(el)
        end
        InputHash.new("attributes" => attrs_hash)
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
      
      def add_attributes!(ret,cmp_type,input_hash,opts={})
        if in_attrs = input_hash["attributes"]
          attrs = OutputHash.new
          in_attrs.each_pair do |name,info|
            external_ref = 
              if opts[:constant_attribute]
                Attribute::Constant.ret_external_ref()
              else
                {"type" => "puppet_attribute", #TODO: hard-wired
                 "path" => "node[#{cmp_type}][#{name}]"
              }
              end
            attr_props = OutputHash.new("display_name" => name,"external_ref" => external_ref)
            add_attr_data_type_attrs!(attr_props,info)
            attr_props["value_asserted"] = info["default"] #setting even when info["default"] so this can handle case where remove a default
            attr_props.set_if_not_nil("description",info["description"])
            attr_props.set_if_not_nil("required",info["required"])
            attrs.merge!(name => attr_props)
          end
          if ret["attribute"]
            ret["attribute"].merge!(attrs)
          else
            ret["attribute"] = attrs
          end
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
        if in_dep_cmps = input_hash["depends_on"]
          convert_to_hash_form(in_dep_cmps) do |conn_ref,conn_info|
            choices = Choice.get_choices(conn_ref,conn_info,base_cmp,opts)

            #determine if create a link def and/or a dependency
            #creaet a dependency if just single choice and base adn depnedncy on same node
            #TODO: only handling addition of dependencies if single choice; consider adding just temporal if multiple choices
            if choices.size == 1 
              choice = choices.first
              if choice.is_internal?()
                pntr = ret[:dependencies] ||= OutputHash.new
                add_dependency!(pntr,choice.dependent_component(),base_cmp)
              end
            end

            #create link defs if there are multiple choices or theer are attribute mappings
            if choices.size > 1 or (choices.size == 1 and choices.first.has_attribute_mappings?())
              link_def = OutputHash.new(
                "type" => get_connection_label(conn_ref,conn_info),
                "required" =>  true, #will be putting optional elements under a key that is peer to 'depends_on'
                "possible_links" => choices
              )
              link_def.set_if_not_nil("description",conn_info["description"])
              link_defs << link_def
            end
          end
        end
        ret[:link_defs] = link_defs unless link_defs.empty?
        ret[:component_order] = component_order(input_hash)
        ret
      end

      class Choice < OutputHash
        def self.get_choices(conn_ref,conn_info,base_cmp,opts={})
          if possible_conn = conn_info["choices"]
            choices.map{|possible_conn|new(possible_conn,base_cmp,conn_info,opts)}
          else
            dep_cmp_external_form = conn_ref||conn_info["component"]
            parent_info=nil
            [new({dep_cmp_external_form => conn_info},base_cmp,parent_info,opts)]
          end
        end

        def initialize(possible_conn,base_cmp,parent_info=nil,opts={})
          unless possible_conn.kind_of?(Hash) and possible_conn.size == 1
            raise ParsingError.new("Ill-formed choice statement in dependency (?1)",possible_conn)
          end
          dep_cmp = ObjectModelForm.convert_to_internal_cmp_form(possible_conn.keys.first)
          dep_cmp_info = possible_conn.values.first
          ret_info = {"type" => link_type(dep_cmp_info,parent_info)}
          in_attr_mappings = (possible_conn["attribute_mappings"]|[]) + parent_info["attribute_mappings"]|[]
          unless in_attr_mappings.empty?
            ret_info["attribute_mappings"] = in_attr_mappings.map{|in_am|convert_attribute_mapping(in_am,base_cmp,dep_cmp,opts)}
          end
          super(convert_to_internal_cmp_form(dep_cmp) => ret_info)
        end

        def is_internal?()
          self["type"] == "internal"
        end
        def dependent_component()
          keys.first
        end

       private
        DefaultLinkType = "local"
        def link_type(link_info,parent_link_info=nil)
          case (link_info["location"]||(parent_link_info||{})["location"]||DefaultLinkType)
           when "local" then "internal"
           when "remote" then "external"
           else raise ParsingError.new("Ill-formed dependency location type (?1)",loc)
          end
        end

      end

      def get_connection_label(conn_ref,conn_info)
        #if component key given then conn_ref will be connection label
        #if there are choices then conn_ref will be connection label
        #otehrwise conn_ref will be component ref and we use the component part for the conenction label
        if conn_info["component"] or conn_info["choices"]
          conn_ref
        else
          cmp_external_form = conn_ref
          component_part(cmp_external_form)
        end
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

      DefaultIsRequired = true
      def is_required?(link_info)
        link_info["required"].nil? ? DefaultIsRequired : link_info["required"]
      end

      def convert_attribute_mapping(input_am,base_cmp,dep_cmp,opts={})
        #TODO: right now only treating constant on right hand side meaning only for <- case
        if input_am =~ /(^[^ ]+)[ ]*->[ ]*([^ ]+$)/
          dep_attr,base_attr = [$1,$2]
          left = convert_attr_ref_simple(dep_attr,:dep,dep_cmp,:output)
          right = convert_attr_ref_simple(base_attr,:base,base_cmp,:input)
        elsif input_am =~ /(^[^ ]+)[ ]*<-[ ]*([^ ]+$)/
          dep_attr,base_attr = [$1,$2]
          left = convert_attr_ref_base(base_attr,base_cmp,dep_attr,dep_cmp,:output,opts)
          right = convert_attr_ref_simple(dep_attr,:dep,dep_cmp,:input)
        else
          raise ParsingError.new("Attribute mapping (?1) is ill-formed",input_am)
        end
        {left => right}
      end

      def convert_attr_ref_simple(attr_ref,dep_or_base,cmp,input_or_output)
        if attr_ref =~ /(^[^.]+)\.([^.]+$)/
          if input_or_output == :input
            raise ParsingError.new("Attribute reference (?1) is ill-formed",attr_ref)
          end
          prefix = $1
          attr = $2
          case prefix
            when "$node" then (dep_or_base == :dep) ? "remote_node" : "local_node"
            else raise ParsingError.new("Attribute reference (?1) is ill-formed",attr_ref)  
          end + ".#{attr.gsub(/host_address$/,"host_addresses_ipv4.0")}"
        else
          dollar_sign,var_name = (attr_ref =~ /(^\$*)(.+$)/; [$1,$2])
          has_dollar_sign = !dollar_sign.empty?
          if (input_or_output == :input and has_dollar_sign) or
              (input_or_output == :output and !has_dollar_sign)
            raise ParsingError.new("Attribute reference (?1) is ill-formed",attr_ref)
          end
          "#{convert_to_internal_cmp_form(cmp)}.#{var_name}"
        end
      end

      def convert_attr_ref_base(attr_ref,base_cmp,dep_attr_ref,dep_cmp,input_or_output,opts={})
        is_constant?(attr_ref,base_cmp,dep_attr_ref,dep_cmp,opts) || convert_attr_ref_simple(attr_ref,:base,base_cmp,input_or_output)
      end

      def is_constant?(attr_ref,base_cmp,dep_attr_ref,dep_cmp,opts={})
        return nil if attr_ref =~ /^\$/

        datatype = :string
        const = attr_ref
        if attr_ref =~ /^'(.+)'$/
          const = $1
        elsif ['true','false'].include?(attr_ref)
          datatype = :boolean
        elsif attr_ref =~ /^[0-9]+$/
          datatype = :integer
        else
          ParsingError.new("Attribute reference (?1) is ill-formed",attr_ref)
        end

        constant_assign = Attribute::Constant.new(const,dep_attr_ref,dep_cmp,datatype)
        (opts[:constants] ||= Array.new) << constant_assign
        "#{convert_to_internal_cmp_form(base_cmp)}.#{constant_assign.attribute_name()}"
      end

      CmpPPDelim = '::'
      def self.convert_to_internal_cmp_form(cmp)
        cmp.gsub(Regexp.new(CmpPPDelim),ModCmpDelim)
      end
      def convert_to_internal_cmp_form(cmp)
        self.class.convert_to_internal_cmp_form(cmp)
      end
      def convert_to_pp_cmp_form(cmp)
        cmp.gsub(Regexp.new(ModCmpDelim),CmpPPDelim)
      end
      def component_part(cmp_external_form)
        if cmp_external_form =~ Regexp.new("^.+#{CmpPPDelim}(.+$)")
          $1
        else
          cmp_external_form
        end
      end

    end
  end
end; end; end

