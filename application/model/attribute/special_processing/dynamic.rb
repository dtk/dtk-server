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
  class Attribute
    class SpecialProcessing
      class Dynamic < self
        def self.special_processing_for_node_components?(action)
          if component = single_component?(action)
            NodeComponent.dynamic_attributes_special_processing?(component)
          end
        end
        
        # retruns  [attribute, partial_value
        #   where attribute is possibly modified attribute passed in
        #   partial_value indicates whether update is a deep merge
        # attribute_value_hash has form {:id=> ..., :value_derived+> }
        def self.update_attribute_if_node_group_member_component(attribute_value_hash, action)
          ret = [attribute_value_hash, false]
          if action.node_group_member?
            value = attribute_value_hash[:value_derived]
            if processed_value = proceess_if_node_group_member_slice?(value, action)
              ret = [attribute_value_hash.merge(value_derived: processed_value), true]
            end
          end
          ret
        end

        private
        
        def self.single_component?(action)
          if action and action.component_actions.size == 1
            action.component_actions[0].component
          end
        end
        
        NODE_GROUP_MEMBER_SLICE_KEY = 'dtk_node_group_member_slice'
        def self.proceess_if_node_group_member_slice?(value, action)
          if value.kind_of?(::Hash) and value.keys.size == 1 and value.keys.first == NODE_GROUP_MEMBER_SLICE_KEY
            processed_value = value.values.first
            qualify_if_needed?(processed_value, action)
          end
        end
        
        def self.qualify_if_needed?(value, action)
          # TODO: DTK-3461 when qualifyng; mismatching the node group members
          # so removing this logic for now
          return value
          
          ret = value
          if node = action.node
            ret = { node.display_name => value }
          else
            Log.error("Unexpected that action.node is nil")
          end
          ret
        end

      end
    end
  end
end

