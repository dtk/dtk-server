module DTK; class ComponentDSL; class V3
  OMFBase = ComponentDSL::V2::ObjectModelForm                                  
  class ObjectModelForm < OMFBase
    class Component < OMFBase::Component
     private
      def body(input_hash,cmp)
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
        ret.set_if_not_nil("component_include_module",include_modules?(input_hash["includes"]))
        if opts[:constants]
          add_attributes!(ret,cmp_type,ret_input_hash_with_constants(opts[:constants]),:constant_attribute => true)
        end
        ret
      end

      def dynamic_default_variable?(info)
        default_indicates_dynamic_default_variable?(info)
      end
      def value_asserted(info) 
        unless default_indicates_dynamic_default_variable?(info)
          info["default"] 
        end
      end
      def default_indicates_dynamic_default_variable?(info)
        info["default"] == ExtRefDefaultPuppetHeader
      end
      ExtRefDefaultPuppetHeader = 'external_ref(puppet_header)'

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
        convert_to_hash_form(in_link_defs) do |dep_cmp,link_def_links|
          choices = Choice.convert_link_defs_to_choices(dep_cmp,link_def_links,base_cmp,opts)
          choices.each do |choice|
            link_def = OutputHash.new(
              "type" => dep_cmp, #TODO: need to factor in use of dependency name
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
          dep_name_match = false
          if dep_choices = ndx_dep_choices[link_def_ndx]
            ndx_dep_choices = {link_def_ndx => dep_choices}
            dep_name_match = true
          end
          link_def_choices.each do |link_def_choice|
            if dn = link_def_choice.dependency_name
              unless dep_name_match
                raise ParsingError.new("The link def segment #{link_def_choice.print_form}) refernces a dependency name (#{dn}) which does not exist")
              end
            end
            unless ndx = find_index(link_def_choice,ndx_dep_choices)
              raise ParsingError.new("Cannot find dependency match for (#{link_def_choice.print_form})")
            end
            (ret[ndx] ||= Array.new) << link_def_choice
          end
        end
        pp [:spliced,ret]
        ret
      end

      def find_index(link_def_choice,ndx_dep_choices)
        ret = nil
        ndx_dep_choices.each do |dep_ndx,dep_choices|
          dep_choices.each do |dep_choice|
            if link_def_matches_dep?(link_def_choice,dep_ndx,dep_choice)
              return dep_ndx
            end
          end
        end
        ret
      end

      def link_def_matches_dep?(link_def_choice,dep_ndx,dep_choice)
        ret = nil
        ld = link_def_choice.possible_link
        dep = dep_choice.possible_link
        unless ld.keys.first == dep.keys.first
          return ret
        end
        ld_props = ld.values.first
        dep_props = dep.values.first
        #TODO: assumng that they both explicitly have type and that is only thing matching on
        ld_props["type"] == dep_props["type"]
      end
    end

    class Choice < OMFBase::Choice
      def self.convert_link_defs_to_choices(dep_cmp,link_def_links,base_cmp,opts={})
        link_def_links.map{|link|convert_link_def_link(link,dep_cmp,base_cmp,opts)}
      end

      def convert_link_def_link(link_def_link,dep_cmp_raw,base_cmp,opts={})
        dep_cmp = convert_to_internal_cmp_form(dep_cmp_raw)
        ret_info = {"type" => LinkDef.link_type(link_def_link)}
        #TODO: pass in order from what is on dependency
        if order = opts[:order]||order(link_def_link)
          ret_info["order"] = order 
        end

        in_attr_mappings = link_def_link["attribute_mappings"]
        if (in_attr_mappings||[]).empty?
          raise ParsingError.new("The link_defs element (#{link_def_link.inspect}) is missing the attribute mappings")
        end
        ret_info["attribute_mappings"] = in_attr_mappings.map{|in_am|convert_attribute_mapping(in_am,base_cmp,dep_cmp,opts)}

        @possible_link.merge!(convert_to_internal_cmp_form(dep_cmp) => ret_info)
        @dependency_name = link_def_link["dependency_name"]
        self
      end

      attr_reader :dependency_name,:link_def_type

     private
      module LinkDef
        DefaultLinkDefLinkType = "remote"
        def self.link_type(link_info)
          loc = link_info["location"]||DefaultLinkDefLinkType
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

