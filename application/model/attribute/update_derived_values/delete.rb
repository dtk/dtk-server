module DTK; class Attribute; class UpdateDerivedValues
  # for processing deleting of links
  class Delete < self
    class LinkInfo
      attr_reader :input_attribute,:other_links
      attr_accessor :deleted_link
      def initialize(input_attribute)
        @input_attribute = input_attribute
        @other_links = Array.new
      end
      def add_other_link!(link)
        @other_links << link
      end
    end

    def self.update_attribute(attr_mh,link_info)
      # if (input) attribute is array then need to splice out; otherwise just need to set to null
      input_index = input_index(link_info.deleted_link)
      if input_index.nil? or input_index.empty?
        set_to_null(attr_mh,link_info)
      else
        splice_out(attr_mh,link_info,input_index)
      end
    end
   private
    def self.set_to_null(attr_mh,link_info)
      row_to_update = {
        :id =>link_info.input_attribute[:id],
        :value_derived => nil
      }
      Model.update_from_rows(attr_mh,[row_to_update])
      old_value_derived = link_info.input_attribute[:value_derived]
      row_to_update.merge(:old_value_derived => old_value_derived)
    end

    def self.splice_out(attr_mh,link_info,input_index)
      pos_to_delete = input_index.first 

      # if this is not an array or last link in output then null
      if pos_to_delete.kind_of?(String) or link_info.other_links.empty?
        return set_to_null(attr_mh,link_info)
      end

      # splice out the value from the deleted link
      ret = nil
      Model.select_process_and_update(attr_mh,[:id,:value_derived],[link_info.input_attribute[:id]]) do |rows|
        # will only be one row; 
        row = rows.first
        val = row[:value_derived]
        ret = {:id => row[:id], :old_value_derived => val.dup?}
        val.delete_at(pos_to_delete)
        ret.merge!(:value_derived => val)
        [row] #row with changed :value_derived
      end
      # renumber other links (ones not deleted) if necessary
      links_to_renumber = link_info.other_links.select do |other_link| 
        input_index(other_link).first > pos_to_delete
      end

      renumber_links(attr_mh,links_to_renumber) unless links_to_renumber.empty?
      ret
    end

    def self.renumber_links(attr_mh,links_to_renumber)
      rows_to_update = links_to_renumber.map do |l|
        new_input_index = input_index(l).dup
        new_input_index[0] -= 1
        new_index_map = [{:output => output_index(l), :input => new_input_index}]
        {:id => l[:attribute_link_id], :index_map => new_index_map}
      end
      Model.update_from_rows(attr_mh.createMH(:attribute_link),rows_to_update)
    end
  end
end; end; end
