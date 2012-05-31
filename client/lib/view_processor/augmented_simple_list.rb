#TODO: test for assembly list/display; want to make assembly specfic stuff datadriven
r8_require 'simple_list'
module R8
  module Client
    class ViewProcAugmentedSimpleList < ViewProcSimpleList
     private
      attr_reader :meta
      def initialize(type,command_class)
        super
        @meta = get_meta(type,command_class)
      end
      def failback_meta(ordered_cols)
        nil
      end
      def simple_value_render(ordered_hash,ident_info)
        super
      end
    end
  end
end
