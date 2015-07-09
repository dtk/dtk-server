module DTK; class Attribute; class UpdateDerivedValues
  # for processing deleting of links
  class Delete < self
    class LinkInfo
      attr_reader :input_attribute, :deleted_links, :other_links
      def initialize(input_attribute)
        @input_attribute = input_attribute
        @deleted_links = []
        @other_links = []
      end

      def add_other_link!(link)
        @other_links << link unless match?(@other_links, link)
      end

      def add_deleted_link!(link)
        @deleted_links << link unless match?(@deleted_links, link)
      end

      private

      def match?(links, link)
        attribute_link_id = link[:attribute_link_id]
        links.find { |l| l[:attribute_link_id] == attribute_link_id }
      end
    end

    def self.update_attribute(attr_mh, link_info)
      # determine if should null out input attribute or instead to splice out indexes from array
      indexes_to_delete = []
      # test link_info.other_links.empty? is a simple way to test whether what is in deleted_links is all
      # the entries in the input attribute
      unless link_info.other_links.empty?
        indexes_to_delete = link_info.deleted_links.map { |link| input_index(link) }.select do |input_index|
          input_index && array_integer?(input_index)
        end
      end

      if indexes_to_delete.empty?
        set_to_null(attr_mh, link_info.input_attribute)
      else
        splice_out(attr_mh, indexes_to_delete, link_info)
      end
    end

    private

    def self.set_to_null(attr_mh, input_attribute)
      row_to_update = {
        id: input_attribute[:id],
        value_derived: nil
      }
      Model.update_from_rows(attr_mh, [row_to_update])
      old_value_derived = input_attribute[:value_derived]
      row_to_update.merge(old_value_derived: old_value_derived)
    end

    IndexPositionInfo = Struct.new(:current_pos, :new_pos, :link)

    # splice out the values in input array from the deleted links and renumber on the other links
    def self.splice_out(attr_mh, _indexes_to_delete, link_info)
      ret = nil
      input_attribute = link_info.input_attribute

      # for other links to facilitate renumbering maintain a renumbering_mapping
      index_pos_info_array = link_info.other_links.map do |link|
        current_pos = array_integer(input_index(link))
        IndexPositionInfo.new(current_pos, current_pos, link)
      end

      # will be interating over delete_positions; reversing order so dont have to renumber this
      delete_positions = link_info.deleted_links.map do |link|
        array_integer(input_index(link))
      end.sort { |a, b| b <=> a }
      Model.select_process_and_update(attr_mh, [:id, :value_derived], [input_attribute[:id]]) do |rows|
        # will only be one row;
        row = rows.first
        val = row[:value_derived]
        ret = { id: row[:id], old_value_derived: val.dup? }
        delete_positions.each do |pos_to_delete|
          val.delete_at(pos_to_delete)
          index_pos_info_array.each do |other_link_info|
            if other_link_info.new_pos > pos_to_delete
              other_link_info.new_pos -= 1
            end
          end
        end
        ret.merge!(value_derived: val)
        [row] #row with changed :value_derived
      end

      renumber_links?(attr_mh, index_pos_info_array)

      ret
    end

    def self.renumber_links?(attr_mh, index_pos_info_array)
      rows_to_update = []
      index_pos_info_array.map do |index_pos_info|
        if index_pos_info.current_pos != index_pos_info.new_pos
          link = index_pos_info.link
          new_index_map = [{ output: output_index(link), input: [index_pos_info.new_pos] }]
          rows_to_update << { id: link[:attribute_link_id], index_map: new_index_map }
        end
      end
      unless rows_to_update.empty?
        Model.update_from_rows(attr_mh.createMH(:attribute_link), rows_to_update)
      end
    end

    def self.array_integer(input_index)
      array_integer?(input_index, no_error_msg: true) ||
        raise(Error.new(error_msg_link_def_index(input_index)))
    end

    def self.array_integer?(input_index, opts = {})
      ret = nil
      if input_index.is_a?(Array) && input_index.size == 1 && input_index.first.is_a?(Fixnum)
        ret = input_index.first
      end
      if ret.nil? && !opts[:no_error_msg]
        Log.error(error_msg_link_def_index(input_index))
      end
      ret
    end

    def self.error_msg_link_def_index(input_index)
      "Unexpected that link def index (#{input_index.inspect}) does not have form: [n]"
    end
  end
end; end; end
