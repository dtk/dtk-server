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
  class CommonModule
    module Import::ServiceModule::Assembly
      module Nodes
        extend FactoryObjectClassMixin

        def self.db_update_hash(container_idh, assembly_ref, parsed_assembly, component_module_refs, opts = {})
          parsed_nodes_with_assembly_wide_components(parsed_assembly).inject(DBUpdateHash.new) do |h, (parsed_node_name, parsed_node)|
            node_ref   = assembly_template_node_ref(assembly_ref, parsed_node_name)
            attributes = Attributes.db_update_hash(parsed_node.val(:Attributes) || []).mark_as_complete
            type       = parsed_node_name.eql?(Node::Type::Node.assembly_wide) ? parsed_node_name : ret_node_type(attributes)

            node_output = {
              'display_name' => parsed_node_name,
              'type'         => type,
              'attribute'    => attributes,
              '*assembly_id' => "/component/#{assembly_ref}"
            }

            # Not using node-bindings in new dsl, instead will retreive node bindings from node property component
            if components = parsed_node.val(:Components)
              node_output['node_binding_rs_id'] = NodePropertyComponent.node_bindings_from_node_property_component(components, container_idh)

              cmps_output = Components.db_update_hash(container_idh, components, component_module_refs, opts)
              node_output['component_ref'] = cmps_output unless cmps_output.empty?
            end

            h.merge(node_ref => node_output)
          end
        end

        private

        def self.ret_node_type(attributes = {})
          return Node::Type::Node.stub unless attributes['type']
          attributes.delete('type')
          Node::Type::NodeGroup.stub
        end

        def self.parsed_nodes_with_assembly_wide_components(parsed_assembly)
          ret = parsed_assembly.val(:Nodes) || CommonDSL::Parse::CanonicalInput::Hash.new
          assembly_wide_components = parsed_assembly.val(:Components)
          unless assembly_wide_components.nil? or assembly_wide_components.empty?
            # assembly wiide components get added under 'fake node' 'assembly_wide'
            node_to_add = CommonDSL::Parse::CanonicalInput::Hash.new
            node_to_add.set(:Components, assembly_wide_components)
            ret.merge!(Node::Type::Node.assembly_wide => node_to_add)
          end
          ret
        end

      end
    end
  end
end
