module DTK; class AttributeLink::UpdateDelta
  class Delete
    class Index < self 
      r8_nested_require('index', 'integer')
      r8_nested_require('index', 'key')
      r8_nested_require('index', 'null')

      def initialize(attr_mh, link_info)
        super()
        @attr_mh   = attr_mh
        @link_info = link_info
      end

      def self.update_indexes!(attr_mh, link_info)
        # determine if indexes are
        # null - (empty)
        # integers, or
        # keys
        index_class(link_info).process!(attr_mh, link_info)
      end

      private

      def self.process!(attr_mh, link_info)
        new(attr_mh, link_info).process!
      end

      def self.index_class(link_info)
        if link_info.other_links.empty?
          Null
        else
          # taking sample link since they are all have same tyoe
          sample_link = link_info.deleted_links.first
          input_index = input_index(sample_link)
          if index_has_type?(:integer, input_index)
            Integer
          elsif index_has_type?(:key, input_index)
            Key
          else
            # TODO: check; this may not be an error; saw it happend on delete assembly
            Log.error(error_msg_link_def_index(input_index))
            Null
          end
        end
      end
        
      # returns input_index.first if matches type
      def self.index_has_type?(type, input_index)
        ret = nil
        if input_index.is_a?(Array) and input_index.size == 1 
          case type
           when :integer 
            input_index.first if input_index.first.is_a?(Fixnum)
           when :key
            input_index.first if input_index.first.is_a?(String)
          end
        end
      end

      def self.error_msg_link_def_index(input_index)
        "Unexpected link_def index for (#{input_index.inspect})"
      end      

      # calling founction should pass block with arg |attr_val| and should pass back its modified version
      def update_attributes(&block_to_compute_new_val)
        ret = nil
        input_attribute = @link_info.input_attribute
        Model.select_process_and_update(@attr_mh, [:id, :value_derived], [input_attribute[:id]]) do |attr_rows|
          # will only be one row; so pull first off and then at end pass single elemnt array
          attr_row = attr_rows.first
          existing_val = attr_row[:value_derived]
          new_val = block_to_compute_new_val.call(existing_val)
          ret = { id: attr_row[:id], old_value_derived: existing_val, value_derived: new_val }
          [attr_row.merge(value_derived: new_val)] # row with changed :value_derived that gets updated in db
        end
        ret
      end
    end
  end
end; end
