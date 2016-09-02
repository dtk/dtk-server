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
module DTK; module CommonDSL 
  class ObjectLogic::Assembly::Node
    class Diff
      class Add < CommonDSL::Diff::Element::Add
        def process
          # TODO: need to recursively add node or node group and then add attributes under it
          # first case on whether node or node group
          pp [:add_node_processing, self]
          pp [:node_type, node_type]
          new_node = assembly_instance.add_node_from_diff(node_name)
          add_node_properties_component(new_node)
          pp [:new_node, new_node]
          nil
        end

        private 

        def add_node_properties_component(node)
          image = nil # TODO: stub
          instance_size = nil # TODO: stub
          # TODO: hard coded to ec2_properties
          assembly_instance.add_ec2_properties_and_set_attributes(project, node, image, instance_size)
        end

        # possible values are :node, or :node_group
        def node_type
          if attributes = node_attributes
            pp [:test, attributes]

            if parsed_type = attributes['type'] && attributes['type'].req(:Value)
              case parsed_type.to_sym
              when :group then :node_group
              else
                fail ErrorUsage, "The type attribute value '#{parsed_type}' on node '#{node_name}' is not a legal node type"
              end
             else
              :node
            end
          end
        end
        
        def node_name
          relative_key
        end
        
        def node_attributes
          @parse_object.val(:Attributes)
        end

      end
    end
  end
end; end
