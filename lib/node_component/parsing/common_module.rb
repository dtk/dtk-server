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
    # The code under Parsing::CommonModule is for parsing modules to look for references to nodes 
    #  - under node section (node_section) or 
    #  - under component section (abstract_node) 
    module Parsing
      class CommonModule
        require_relative('common_module/abstract_node')
        require_relative('common_module/node_section')
        require_relative('common_module/node_attribute')
        def self.process_node_components!(parsed_assembly)
          # For both nodes under node section and abstract node componenst under component section the methods below move it into form where
          # There is an explicit entry under :nodes with node name as key, no attributes, but all nested components
          # There is an entry under :components that is teh component type associated wityh an asbtract node or node group that has the node related attributes
          NodeSection.process_nodes_in_node_section!(parsed_assembly)
          AbstractNode.process_abstract_node_components!(parsed_assembly)
        end
        
        private

        def self.iaas_type
          # TODO: DTK-2967: node component is hard wired to iaas-specfic and to ec2 as iaas choice
          :ec2
        end

        # opts can have keys
        #   :node_content
        def self.find_or_add_node_component!(parsed_assembly, iaas_type, node_name, node_type, opts = {})
          ret = nil
          parsed_components  = parsed_assembly.val(:Components)
          node_component_ref = NodeComponent.node_component_ref(iaas_type, node_name,  node_type: node_type)
          if match = matching_component?(parsed_components, node_component_ref)
            ret = match
          else
            ret = canonical_hash.merge(node_component_ref => opts[:node_content] || canonical_hash)
            unless parsed_components
              parsed_components = canonical_hash
              parsed_assembly.set(:Components, parsed_components)
            end
            parsed_components.merge!(ret)
          end
          ret
        end

        def self.matching_component?(parsed_components, component_name)
          if match_in_array_form = (parsed_components && parsed_components.find { |name, parsed_component| name == component_name })
            canonical_hash.merge(component_name => match_in_array_form[1])
          end
        end

        def self.canonical_hash(hash = {})
          ret = CommonDSL::Parse::CanonicalInput::Hash.new
          hash.each_pair { |k, v| ret.set(k, v) }
          ret
        end

        def self.find_attribute_value?(parsed_attributes, target_attribute_name)
          if match = parsed_attributes.find { |attribute_name, parsed_attribute| attribute_name == target_attribute_name }
            match[1].val(:Value)
          end
        end

        # this method looks under top_key in parsed_node_or_component for a hash and if so removes the keys nested_keys_to_remove in it
        def self.remove_keys!(parsed_node_or_component, top_key, nested_keys_to_remove) 
          return if nested_keys_to_remove.empty?
          if parse_hash = parsed_node_or_component.val(top_key) 
            update_hash = parse_hash.inject(canonical_hash) do |h, (name, v)|
              nested_keys_to_remove.include?(name) ? h : h.merge(name => v)
            end       
          end
          parsed_node_or_component.set(top_key, update_hash)
        end

      end
    end
  end
end
