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
      attr_reader :dep_cmp_name,:base_cmp
      def dep_cmp()
        convert_to_internal_cmp_form(@dep_cmp_name)
      end
    end
  end
end; end; end


