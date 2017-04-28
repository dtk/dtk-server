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
  class Attribute::SpecialProcessing
    class GroupCardinality < self
      def initialize(attribute, component, new_val)
        super(attribute, component, new_val.to_i)
      end
      
      def process
        existing_val = (attribute.get_field?(:value_asserted) || 0).to_i
        # no op if no change
        return if new_val == existing_val

        node_group = NodeComponent.node_component(component).node_group
        ng_members = node_group.get_node_group_members
        
        # existing_val is value of cardinality attributes, and in some cases can be different than node_group_members.size
        # because node_group_members can be marked for deletion (not actually deleted) and will be deleted on converge
        if new_val > existing_val
          if new_val == ng_members.size
            ng_members.each{ |ngm| ngm.update(:ng_member_deleted => false) }
          elsif new_val > ng_members.size
            ng_members.each{ |ngm| ngm.update(:ng_member_deleted => false) }
            node_group.add_group_members(new_val)
          else
            sorted = ng_members.sort_by { |ngm| ngm[:index] }
            ng_members_reuse = sorted.first(new_val)
            ng_members_reuse.each{ |ngm| ngm.update(:ng_member_deleted => false) }
          end
        elsif new_val < existing_val
          node_group.delete_group_members(new_val, true)
        else
          ng_members.each{ |ngm| ngm.update(:ng_member_deleted => false) }
        end
      end
    end
    
  end
end

