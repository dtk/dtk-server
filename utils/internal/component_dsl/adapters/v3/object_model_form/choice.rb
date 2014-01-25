module DTK; class ComponentDSL; class V3
  class ObjectModelForm
    class Choice < OMFBase::Choice
      r8_nested_require('choice','dependency')
      r8_nested_require('choice','link_def_link')

      def initialize(raw,dep_cmp_name,base_cmp)
        super()
        @raw = raw
        @dep_cmp_name = dep_cmp_name
        @base_cmp  = base_cmp
      end

      def print_form()
        @raw || @possible_link.inject()
      end
      def base_cmp_print_form()
        component_print_form(base_cmp())
      end
      def dep_cmp_print_form()
        component_print_form(dep_cmp())
      end

      def remote_location?()
        ret_single_possible_link_value()["type"] == "external"
      end
      def set_to_local_location_as_default()
        if ret_single_possible_link_value()["type"].nil?
          update_single_possible_link_value("type" => "internal")
        end
      end

      #returns [dependencies,link_defs]
      def self.deps_and_link_defs(input_hash,base_cmp,opts={}) 
        ndx_dep_choices = Dependency.ndx_dep_choices(input_hash["dependencies"],base_cmp,opts)
        spliced_ndx_link_def_links = LinkDef.spliced_ndx_link_def_links(input_hash["link_defs"],base_cmp,ndx_dep_choices,opts)
        integrate_deps_and_link_defs!(ndx_dep_choices,spliced_ndx_link_def_links)
pp [:after_add_dependent_components,ndx_dep_choices,spliced_ndx_link_def_links]
        dependencies = Dependency.dependencies?(ndx_dep_choices.values,base_cmp,opts)
        link_defs = LinkDef.link_defs?(spliced_ndx_link_def_links)
        [dependencies,link_defs]
      end

      def matches?(choice_with_single_pl)
        ret = nil
        if pl_match_props =  matches_on_keys?(choice_with_single_pl)
          pl_single_props = choice_with_single_pl.possible_link.values.first
          pl_match_props["type"] == pl_single_props["type"]
        end
      end

     private
      def set_single_possible_link!(ndx,hash_value)
        unless @possible_link.empty?
          raise Error.new("Unexpected that @possible_link is not empty when adding an element")
        end
        @possible_link.merge!(ndx => hash_value)
      end
      def update_single_possible_link_value(hash_value)
        unless @possible_link.size == 1
          raise Error.new("Unexpected that @possible_link has size unequal to 1")
        end
        @possible_link.values.first.merge!(hash_value)
      end
      def ret_single_possible_link_value()
        ret_single_possible_link().values.first||{}
      end
      def ret_single_possible_link()
        unless [0,1].include?(@possible_link.size)
          raise Error.new("Unexpected that @possible_link has size greater than 1")
        end
        @possible_link
      end

      attr_reader :dep_cmp_name,:base_cmp
      def dep_cmp()
        convert_to_internal_cmp_form(@dep_cmp_name)
      end
      def dup()
        self.class.new(@raw,@dep_cmp_name,@base_cmp)
      end

      def self.integrate_deps_and_link_defs!(ndx_dep_choices,spliced_ndx_link_def_links)
        #throw error if there are any unmatched ndx_dep_choices that have a remote location
        #remove any simple dependencies that match a link def
        ndx_dep_choices.each do |ndx,dep_choices|
          if spliced_ndx_link_def_links[ndx]
            #the dep matches a link def; we are purposely not matching on location a
            ndx_dep_choices.delete(ndx)
          else
            #this relies on assumption that if in dsl there is no location given for dep, it is set to location local
            if remote_dep_choice = dep_choices.find{|dep_choice|dep_choice.remote_location?()}
              error_msg = "The following dependency on component '?base_cmp' has a remote location, but there is no matching link def: ?dep"
              raise ParsingError::Dependency.create(error_msg,remote_dep_choice)
            else
              dep_choices.each{|dep_choice|dep_choice.set_to_local_location_as_default()}
            end
          end
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

    end
  end
end; end; end


