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
module DTK
  class Node
    class Instance < self
      def self.component_list_fields
        [:id, :display_name, :group_id, :external_ref, :ordered_component_ids]
      end

      def self.get(mh, opts = {})
        sp_hash = {
          cols: ([:id, :group_id, :display_name] + (opts[:cols] || [])).uniq,
          filter: [:neq, :datacenter_datacenter_id, nil]
        }
        get_objs(mh, sp_hash)
      end

      def self.get_unique_instance_name(mh, display_name)
        display_name_regexp = Regexp.new("^#{display_name}")
        matches = get(mh, cols: [:display_name]).select { |r| r[:display_name] =~ display_name_regexp }
        if matches.empty?
          return display_name
        end
        index = 2
        matches.each do |r|
          instance_name = r[:display_name]
          if instance_name =~ /-([0-9]+$)/
            instance_index = Regexp.last_match(1).to_i
            if instance_index >= index
              index += 1
            end
          end
        end
        "#{display_name}-#{index}"
      end
    end
  end
end