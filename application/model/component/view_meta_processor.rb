module XYZ
  module ComponentViewMetaProcessor
    def create_view_meta_from_layout_def(view_type,layout_def)
      case view_type
        when :edit then ViewMetaProcessorInternals.create_from_layout_def__edit(layout_def)
        else raise Error.new("not implemented for view type #{view_type}")
      end
    end

    module ViewMetaProcessorInternals
      def self.create_from_layout_def__edit(layout_def)
        ret = ActiveSupport::OrderedHash.new()
        ret[:action] = ''
        ret[:hidden_fields] = hidden_fields(:edit)
        ret[:field_groups] = field_groups(layout_def)
        ret
      end

      def self.field_groups(layout_def)
        (layout_def[:groups]||[]).map do |group|
          {num_cols: 1,
            display_labels: true,
            fields: group[:fields].map {|r|{r[:name].to_sym => r}}
          }
        end
      end

      def self.hidden_fields(type)
        HiddenFields[type].map do |hf|
          {hf.keys.first => Aux::ordered_hash_subset(hf.values.first,[:required,:type,:value])}
        end
      end
      HiddenFields = {
        list:         [
         {id: {
             required: true,
             type: 'hidden'
           }}
        ],
        edit:         [
         {
           id: {
             required: true,
             type: 'hidden'
           }
         },
         {
           model: {
             required: true,
             type: 'hidden',
             value: 'component'
           }
         },
         {
           action: {
             required: true,
             type: 'hidden',
             value: 'save_attribute'
           }
         }
        ],
        display:         [
         {
           id: {
             required: true,
             type: 'hidden'
           }
         },
         {
           obj: {
             required: true,
             type: 'hidden',
             value: 'component'
           }
         },
         {
           action: {
             required: true,
             type: 'hidden',
             value: 'edit'
           }
         }
        ]
      }
    end
  end
end
