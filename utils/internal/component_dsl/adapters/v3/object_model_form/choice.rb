module DTK; class ComponentDSL; class V3
  class ObjectModelForm
    class Choice < OMFBase::Choice
      r8_nested_require('choice','dependency')
      r8_nested_require('choice','link_def')

      def initialize(raw,dep_cmp_name,base_cmp)
        super()
        @raw = raw
        @dep_cmp_name = dep_cmp_name
        @base_cmp  = base_cmp
      end

      #processes "link_defs, "dependencies", and "component_order"
      def self.add_dependent_components!(cmp_ret,input_hash,base_cmp,opts={})
        ndx_dep_choices = Hash.new
        if in_dep_cmps = input_hash["dependencies"]
          convert_to_hash_form(in_dep_cmps) do |conn_ref,conn_info|
            choices = Dependency.convert_choices(conn_ref,conn_info,base_cmp,opts)
            ndx_dep_choices.merge!(conn_ref => choices)
          end
          internal_dependencies = internal_dependencies(ndx_dep_choices.values,base_cmp,opts)
          cmp_ret.set_if_not_nil("dependency",internal_dependencies)
        end

        link_defs = link_defs(input_hash,base_cmp,ndx_dep_choices,opts)
        cmp_ret.set_if_not_nil("link_defs",link_defs)
        cmp_ret.set_if_not_nil("component_order",component_order(input_hash))
      end

      def dup()
        self.class.new(@raw,@dep_cmp_name,@base_cmp)
      end
      private :dup

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
        ((@possible_link||{}).values.first||{})["type"] == "external"
      end

     private
      def self.internal_dependencies(choices_array,base_cmp,opts={})
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

      attr_reader :dep_cmp_name,:base_cmp
      def dep_cmp()
        convert_to_internal_cmp_form(@dep_cmp_name)
      end
    end
  end
end; end; end


