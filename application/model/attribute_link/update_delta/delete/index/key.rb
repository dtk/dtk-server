#
# Copyright (C) 2010-2016 dtk contributors
#
# This file is part of the dtk project.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
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