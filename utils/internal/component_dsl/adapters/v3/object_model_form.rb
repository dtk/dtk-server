module DTK; class ComponentDSL; class V3
  OMFBase = ComponentDSL::V2::ObjectModelForm                                  
  class ObjectModelForm < OMFBase
   private
    def context(input_hash)
      ret = super
      if module_level_includes = input_hash["includes"]
        ret.merge!(:module_level_includes => module_level_includes)
      end
      ret
    end

    class Component < OMFBase::Component
     private
      def body(input_hash,cmp,context={})
        pp [:in,self.class]
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
        ret.set_if_not_nil("component_include_module",include_modules?(input_hash["includes"],context))
        if opts[:constants]
          add_attributes!(ret,cmp_type,ret_input_hash_with_constants(opts[:constants]),:constant_attribute => true)
        end
        ret
      end

      def include_modules?(incl_module_array,context={})
        if module_level_includes = context[:module_level_includes]
          more_specific_incls = super(incl_module_array)
          less_specific_incls = super(module_level_includes)
          combine_includes(more_specific_incls,less_specific_incls)
        else
          super(incl_module_array)
        end
      end

      def add_attr_data_type_attrs!(attr_props,info)
        type = info['type']||DefaultDatatype
        if type =~ /^array/
          nested_type = 'string'
          if type == 'array'
            type = 'array(string)'
          elsif type =~ /^array\((.+)\)$/ 
            nested_type = $1
          else
            raise ParsingError.new("Ill-formed attribute data type (?1)",type)
          end
          #TODO: this will be modified when clean up attribute properties for semantic dataype
          if AttributeSemanticType.isa?(nested_type)
            to_add = {
              "data_type" => AttributeSemanticType.datatype("array").to_s,
              "semantic_type_summary" => type,
              "semantic_type" => {":array" => nested_type},
              "semantic_data_type" => "array"
            }
            attr_props.merge!(to_add)
          end
        elsif AttributeSemanticType.isa?(type)
          attr_props.merge!("data_type" => AttributeSemanticType.datatype(type).to_s,"semantic_data_type" => type)
        end

        unless attr_props["data_type"]
          raise ParsingError.new("Ill-formed attribute data type (?1)",type)
        end
        attr_props
      end

      DefaultDatatype = "string"

      def dynamic_default_variable?(info)
        default_indicates_dynamic_default_variable?(info)
      end
      def value_asserted(info,attr_props) 
        unless default_indicates_dynamic_default_variable?(info)
          ret = nil
          value = info["default"] 
          unless value.nil?
            if semantic_data_type = attr_props["semantic_data_type"]
              #TODO: currently converting 'integer' -> integer and 'booelan' -> boolean; this may be unnecesary since the object model stores everything as strings
              ret = AttributeSemanticType.convert_and_raise_error_if_not_valid(semantic_data_type,value,:attribute_name => attr_props['display_name'])
            end
            ret
          else
            nil #just to emphasize want to return nil when no value given
          end
        end
      end
      def default_indicates_dynamic_default_variable?(info)
        info["default"] == ExtRefDefaultPuppetHeader
      end
      ExtRefDefaultPuppetHeader = 'external_ref(puppet_header)'

      module AttributeSemanticType
        def self.isa?(semantic_type)
          apply('isa?'.to_sym,semantic_type)
        end
        def self.datatype(semantic_type)
          apply(:datatype,semantic_type)
        end
        def self.convert_and_raise_error_if_not_valid(semantic_type,value,opts={})
          apply(:convert_and_raise_error_if_not_valid,semantic_type,value,opts)
        end

       private
        def self.apply(*method_then_args)
          ::DTK::Attribute::SemanticDatatype.send(*method_then_args)
        end
      end

      #processes "link_defs, "dependencies", and "component_order"
      def add_dependent_components!(ret,input_hash,base_cmp,opts={})
        ndx_dep_choices = Hash.new
        if in_dep_cmps = input_hash["dependencies"]
          convert_to_hash_form(in_dep_cmps) do |conn_ref,conn_info|
            choices = Choice.convert_choices(conn_ref,conn_info,base_cmp,opts)
            ndx_dep_choices.merge!(conn_ref => choices)
          end
          internal_dependencies = internal_dependencies(ndx_dep_choices.values,base_cmp,opts)
          ret.set_if_not_nil("dependency",internal_dependencies)
        end

        link_defs = link_defs(input_hash,base_cmp,ndx_dep_choices,opts)
        ret.set_if_not_nil("link_defs",link_defs)
        ret.set_if_not_nil("component_order",component_order(input_hash))
      end

      def internal_dependencies(choices_array,base_cmp,opts={})
        ret = nil
        choices_array.each do |choices|
          #can only express necessarily need component on same node; so if multipe choices only doing so iff all are internal
          unless choices.find{|choice|not choice.is_internal?()}
            #TODO: make sure it is ok to just pick one of these
            choice = choices.first
            ret ||= OutputHash.new
            add_dependency!(ret,choice.dependent_component(),base_cmp)
          end
        end
        ret
      end

      def link_defs(input_hash,base_cmp,ndx_dep_choices,opts={})
        ret = nil
        unless in_link_defs = input_hash["link_defs"]
          #TODO: flag any dep_choices that are remote; saying thaey have no effect without link defs
          return ret
        end
        ndx_link_defs = ndx_link_defs_choice_form(in_link_defs,base_cmp,opts)
        spliced_ndx_link_defs = splice_link_def_and_dep_info(ndx_link_defs,ndx_dep_choices)
        ret = Array.new
        spliced_ndx_link_defs.each do |link_def_type,choices|
          choices.each do |choice|
            link_def = OutputHash.new(
              "type" => link_def_type,
              "required" =>  true, #TODO: will enhance so that check if also dependency
              "possible_links" => choices.map{|choice|choice.possible_link()}
            )
            ret << link_def
          end
        end
        ret
      end

      def ndx_link_defs_choice_form(in_link_defs,base_cmp,opts={})
        ret = Hash.new
        convert_to_hash_form(in_link_defs) do |dep_cmp,link_def_links|
          link_def_links = [link_def_links] unless link_def_links.kind_of?(Array)
          choices = Choice.convert_link_defs_to_choices(dep_cmp,link_def_links,base_cmp,opts)
          choices.each do |choice|
            ndx = choice.dependency_name || dep_cmp
            (ret[ndx] ||= Array.new) << choice
          end
        end
        ret
      end

      def splice_link_def_and_dep_info(ndx_link_defs,ndx_dep_choices)
        ret = Hash.new
        ndx_link_defs.each do |link_def_ndx,link_def_choices|
          pruned_ndx_dep_choices = ndx_dep_choices
          dep_name_match = false
          if dep_choices = ndx_dep_choices[link_def_ndx]
            pruned_ndx_dep_choices = {link_def_ndx => dep_choices}
            dep_name_match = true
          end
          link_def_choices.each do |link_def_choice|
            if dn = link_def_choice.dependency_name
              unless dep_name_match
                raise ParsingError.new("The link def segment #{link_def_choice.print_form}) refernces a dependency name (#{dn}) which does not exist")
              end
            end
            unless ndx = find_index(link_def_choice,pruned_ndx_dep_choices)
              dep_cmp_name = ::DTK::Component.display_name_print_form(link_def_choice.dep_cmp)
              base_cmp_name = ::DTK::Component.display_name_print_form(link_def_choice.base_cmp)
              error_msg = "Cannot find dependency match for link_def for component '#{base_cmp_name}' to '#{dep_cmp_name}'; the link fragment is: ?1"
              raise ParsingError.new(error_msg,link_def_choice.print_form())
            end
            (ret[ndx] ||= Array.new) << link_def_choice
          end
        end
        ret
      end

      def find_index(link_def_choice,ndx_dep_choices)
        ret = nil
        ndx_dep_choices.each do |dep_ndx,dep_choices|
          dep_choices.each do |dep_choice|
            if dep_choice.matches?(link_def_choice)
              return dep_ndx
            end
          end
        end
        ret
      end

    end

    class Choice < OMFBase::Choice
      attr_reader :dep_cmp,:base_cmp
      def print_form()
        @raw || @possible_link.inject()
      end

      def self.convert_link_defs_to_choices(dep_cmp,link_def_links,base_cmp,opts={})
        link_def_links.inject(Array.new) do |a,link|
          a + convert_link_def_link(link,dep_cmp,base_cmp,opts)
        end
      end

      def convert_link_def_link(link_def_link,dep_cmp_raw,base_cmp,opts={})
        @raw = link_def_link
        @dep_cmp = convert_to_internal_cmp_form(dep_cmp_raw)
        @base_cmp  = base_cmp

        unless type = opts[:link_type] || link_def_link_type(link_def_link)
          ret = [self.class.new.convert_link_def_link(link_def_link,dep_cmp_raw,base_cmp,:link_type => :external).first,
                 self.class.new.convert_link_def_link(link_def_link,dep_cmp_raw,base_cmp,:link_type => :internal).first]
          return ret
        end
        ret_info = {"type" => type.to_s}

        #TODO: pass in order from what is on dependency
        if order = opts[:order]||order(link_def_link)
          ret_info["order"] = order 
        end

        in_attr_mappings = link_def_link["attribute_mappings"]
        if (in_attr_mappings||[]).empty?
          raise ParsingError.new("The link_defs element (#{link_def_link.inspect}) is missing the attribute mappings")
        end
        ret_info["attribute_mappings"] = in_attr_mappings.map{|in_am|convert_attribute_mapping(in_am,base_cmp,@dep_cmp,opts)}
        
        @possible_link.merge!(convert_to_internal_cmp_form(@dep_cmp) => ret_info)
        @dependency_name = link_def_link["dependency_name"]
        [self]
      end

      attr_reader :dependency_name,:link_def_type

      def matches?(choice_with_single_pl)
        ret = nil
        if pl_match_props =  matches_on_keys?(choice_with_single_pl)
          pl_single_props = choice_with_single_pl.possible_link.values.first
          pl_match_props["type"] == pl_single_props["type"]
        end
      end
      def matches_on_keys?(choice_with_single_pl)
        ret = nil
        pl_single = choice_with_single_pl.possible_link
        unless pl_single.size == 1
          raise Error.new("Unexepected that (#{pl_single.print_form}) has size > 1")
        end
        possible_link[pl_single.keys.first]
      end

    private
     def link_def_link_type(link_info)
       if loc = link_info["location"]
         case loc
           when "local" then "internal"
           when "remote" then "external"
           else raise ParsingError.new("Ill-formed dependency location type (?1)",loc)
         end
       end
     end

      def self.convert_link_def_link(link_def_link,dep_cmp,base_cmp,opts={})
        new().convert_link_def_link(link_def_link,dep_cmp,base_cmp,opts)
      end
    end
  end
end; end; end

