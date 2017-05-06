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
  class NodeComponent
    class Parsing::CommonModule
      class AbstractNode < self
        def self.add_node_components!(parsed_assembly)
          if parsed_components = parsed_assembly.val(:Components)
            
            nodes_to_add = parsed_components.inject([]) do |a, (component_name, parsed_component)|
              (node_info = abstract_node_info?(component_name, parsed_component)) ? a + [node_info] : a
            end
            nodes_to_add.each do |node_info|
              find_or_add_node_component!(parsed_assembly, iaas_type, node_info.name, node_info.type, node_content: node_info.content) 
            end
          end
        end
        
        private
        
        NodeInfo = Struct.new(:name, :type, :content)
        # returns Info if this component is an abstract node; otherwise nil
        PARSING_MAP = {
          Type::SINGLE =>  /^node\[([^\]]+)\]$/,
          Type::GROUP  => /^node_group\[([^\]]+)\]$/
        }
        
        def self.abstract_node_info?(component_name, parsed_component)
          PARSING_MAP.each do |node_type, regexp|
            if component_name =~ regexp
              node_name = $1
              return NodeInfo.new(node_name, node_type, parsed_component)
            end
          end
          nil
        end
        
      end
    end
  end
end
