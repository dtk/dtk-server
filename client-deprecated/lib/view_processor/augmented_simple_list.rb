#TODO: test for assembly list/display; want to make assembly specfic stuff datadriven
dtk_require 'simple_list'
module DTK
  module Client
    class ViewProcAugmentedSimpleList < ViewProcSimpleList
     private
      def initialize(type,command_class)
        super
        @meta = get_meta(type,command_class)
      end
      def failback_meta(ordered_cols)
        nil
      end
      def simple_value_render(ordered_hash,ident_info)
        augmented_def?(ordered_hash,ident_info) || super
      end
      def augmented_def?(ordered_hash,ident_info)
        return nil unless @meta
        if aug_def =  @meta["#{ordered_hash.object_type}_def".to_sym]
          ident_str = ident_str(ident_info[:ident]||0)
          vals = aug_def[:keys].map{|k|ordered_hash[k.to_s]}
          "#{ident_str}#{aug_def[:fn].call(*vals)}\n"
        end
      end
    end
  end
end
