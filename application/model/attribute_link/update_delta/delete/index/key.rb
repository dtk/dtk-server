module DTK; class AttributeLink::UpdateDelta::Delete
  class Index
    class Key < self
      def process!
        remove_entries_at_keys!
      end

      private

      def remove_entries_at_keys!
        delete_keys = @link_info.deleted_links.map { |link| key_index(link) }
        update_attributes do |existing_hash_attr_val|
          new_val = {}
          existing_hash_attr_val.each_pair do |k, v|
            new_val[k] = v unless delete_keys.include?(k)
          end
          new_val
        end
      end

      def key_index(link)
        input_index = input_index(link)
        Index.index_has_type?(:key, input_index) || Index.error_msg_link_def_index(input_index)
      end

    end
  end
end; end
