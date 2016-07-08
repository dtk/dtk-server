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
  class CommonModule::Import::ServiceModule
    module Assembly
      module Nodes
        extend FactoryObjectClassMixin

        def self.db_update_hash(container_idh, assembly_ref, parsed_nodes, component_module_refs, opts = {})
          unless parsed_nodes.is_a?(Array)
            fail ParsingError.new('Nodes section is ill-formed', opts_file_path(opts))
          end

          parsed_nodes.inject(DBUpdateHash.new) do |h, node_hash|
            if node_hash && node_hash.is_a?(String)
              node_hash = { name: node_hash }
            end

            node_hash ||= {}
            node_hash_ref = node_hash.req(:Name)
            node_ref      = assembly_template_node_ref(assembly_ref, node_hash_ref)

            unless (node_hash || {}).is_a?(Hash)
              fail ParsingError.new("The content associated with key (#{node_hash_ref}) should be a hash representing assembly node info", opts_file_path(opts))
            end

            attributes = Attributes.db_update_hash(node_hash.val(:Attributes) || []).mark_as_complete
            type       = node_hash_ref.eql?(Node::Type::Node.assembly_wide) ? node_hash_ref : ret_node_type(attributes)

            node_output = {
              'display_name' => node_hash_ref,
              'type' => type,
              'attribute' => attributes,
              '*assembly_id' => "/component/#{assembly_ref}"
            }

            # we are not going to use node-bindings in new dsl, instead will retreive node bindings from node property component
            components = node_hash['components']

            if components
              node_output['node_binding_rs_id'] = CommonModule::BaseService::NodePropertyComponent.node_bindings_from_node_property_component(components, container_idh)

              # Aldin: 07/04/2016 - need to rewrite this part without version_proc_class
              # if version_proc_class = opts[:version_proc_class]
                # cmps_output = version_proc_class.import_component_refs(container_idh, opts[:default_assembly_name], components, component_module_refs, opts)

                cmps_output = Components.db_update_hash(container_idh, components, component_module_refs, opts)

                unless cmps_output.empty?
                  node_output['component_ref'] = cmps_output
                end
              # end
            end

            h.merge(node_ref => node_output)
          end
        end

        def self.ret_node_type(attributes = {})
          return Node::Type::Node.stub unless attributes['type']
          attributes.delete('type')
          Node::Type::NodeGroup.stub
        end
      end
    end
  end
end
