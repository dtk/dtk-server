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
    class IAAS
      module HostAttributes
        ATTRIBUTES = [:host_addresses_ipv4]
        def self.link_to_node(node_component)
          node_attributes    = node_component.node.get_node_attributes(filter: [:oneof, :display_name, ATTRIBUTES.map(&:to_s)])
          ndx_node_attributes = node_attributes.inject({}) {  |h, attribute| h.merge(attribute.display_name.to_sym => attribute) }

          ATTRIBUTES.each do |attribute_name|
            component_attribute = node_component.attribute(attribute_name)
            node_attribute      = ndx_node_attributes[attribute_name]
            add_attribute_link(node_component.assembly, component_attribute, node_attribute)
          end
        end

        private
        
        def self.add_attribute_link(assembly, component_attribute, node_attribute)
          AttributeLink::AdHoc.create_simple(assembly, input_attribute: node_attribute, output_attribute: component_attribute)
        end
      end

    end
  end
end
