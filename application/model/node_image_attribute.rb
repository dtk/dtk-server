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
  class NodeImageAttribute < Model
    class Size < self
      def self.find_iaas_match(target, logical_size)
        legacy_bridge_to_node_template(target, logical_size)
      end

      private

      def self.legacy_bridge_to_node_template(target, logical_size)
        ret = nil
        opts_get = { cols: [:id, :group_id, :ref, :rules, :os_type] }
        matching_nbrs = Node::Template.get_matching_node_binding_rules(target, opts_get)
        if matching_nbrs.empty?
          return ret
        end
        # HACK: to use nbrs to find size only info
        match = matching_nbrs.find do |nbr|
          nbr[:ref] =~ Regexp.new("-#{logical_size}$")
        end
        if match
          match[:matching_rule][:node_template][:size]
        end
      end
    end
  end
end