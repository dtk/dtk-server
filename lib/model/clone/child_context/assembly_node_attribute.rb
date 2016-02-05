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
module DTK; class Clone
  class ChildContext
    class AssemblyNodeAttribute < self
      private

      def parent_rels
        # add to parent relationship, which is between new node and node template, relationship between new node and node (stub)
        ret_from_node_template = self[:parent_rels]
        ndx_nt_to_node = self[:parent_objs_info].inject({}) do |h, r|
          h.merge(r[:node_template_id] => r[:ancestor_id])
        end
        ret_from_node = self[:parent_objs_info].map do |r|
          { node_node_id: r[:id], old_par_id: r[:ancestor_id] }
        end
        ret_from_node_template + ret_from_node
      end
    end
  end
end; end