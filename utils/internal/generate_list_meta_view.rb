# TODO: should this go in utils/internal dir?
module XYZ
  module GenerateListMetaView
    # TODO: may pass in a sample row to use as default when no fieldset the Ruby datatype
    def generate_list_meta_view(columns,relation)
      {
        tr_class: Local.tr_class,
        hidden_fields: Local.hidden_fields(),
        field_list: Local.field_list(columns,relation)
      }
    end
    module Local
      def self.tr_class
        'tr-dl'
      end
      def self.hidden_fields
        [
         {id: {
            required: true,
             type: 'hidden'
          }}
        ]
      end

      def self.field_list(columns,relation)
        fieldset_types = Model::FieldSet.scalar_cols_with_types(relation) || []
        (columns.empty? ? Model::FieldSet.default(relation).cols : columns).map do |col|
          {col => {
              type: ui_datatype(col,fieldset_types),
              help: ''
            }.merge(col == :display_name ? {objLink: true, objLinkView: 'display'} : {}) #TODO: hard coded display name as one with links
          }
        end
      end

      private

      def self.ui_datatype(col,fieldset_types)
        fieldset_type = fieldset_types[col]
        (DefaultMappingFromFieldSet[fieldset_type] || DefaultUIType).to_s
      end
      DefaultUIType = :text
      DefaultMappingFromFieldSet = {
        json: :hash,
        string: :text,
        text: :text,
        varchar: :text,
        bigint: :integer,
        integer: :integer,
        int: :integer,
        numeric: :text,
        boolean: :text #TODO: stub
      }
    end
  end
end
