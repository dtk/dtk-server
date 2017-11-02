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
  class Assembly::Template
    class Stage
      class AssemblyAttributeLinks
        # TODO DTK-2999: will refactor
        def initialize(assembly_instance)
          @assembly_instance    = assembly_instance
          @target               = assembly_instance.get_target
          @assembly_attributes  = assembly_instance.get_assembly_level_attributes
          @component_attributes = assembly_instance.get_augmented_component_attributes
          @node_attributes      = []  # TODO: stub
          # dynamically set
          @links               = []
          @propagate           = []
        end
        private :initialize
        
        def self.add(assembly_instance)
          new(assembly_instance).add
        end
        
        def add 
          self.assembly_attributes.each do |assembly_attribute|
            add_assembly_attribute_info!(assembly_attribute)
          end
          @links.compact!
          
          Model.create_from_rows(target_child_mh(:attribute_link), @links, convert: true)
          # this will propagate attribute value through link_to and link_from when staging service instance
          Attribute.propagate_and_optionally_add_state_changes(target_child_mh(:attribute), @propagate) unless @propagate.empty?
        end
        
        protected

        attr_reader :assembly_instance, :target, :assembly_attributes, :component_attributes, :node_attributes
        
        private
        
        def model_handle(model_name)
          self.assembly_instance.model_handle(model_name)
        end
        
        def target_child_mh(model_name)
          self.target.model_handle.create_childMH(model_name)
        end

        def add_assembly_attribute_info!(assembly_attribute)
          assembly_template_id = assembly_attribute[:ancestor_id]
          attribute_links_to   = AttributeLinkTo.get_for_attribute_id(model_handle(:attribute_link_to), assembly_template_id)
          attribute_links_from = AttributeLinkFrom.get_for_attribute_id(model_handle(:attribute_link_from), assembly_template_id)
          @links += attribute_links_to.map do |attribute_link_to|
            if matching_attribute = find_matching_attribute?(attribute_link_to[:component_ref])
              if value_asserted = assembly_attribute[:value_asserted]
                @propagate << propagate_hash(assembly_attribute.id, value_asserted)
              end
              attribute_link(:to, assembly_attribute.id, matching_attribute.id)
            end
          end
          
          @links += attribute_links_from.map do |attribute_link_from|
            if matching_attribute = find_matching_attribute?(attribute_link_from[:component_ref])
              if value_asserted = matching_attribute[:value_asserted]
                @propagate << propagate_hash(matching_attribute.id, value_asserted)
              end
              attribute_link(:from, assembly_attribute.id, matching_attribute.id)
            end
          end
        end

        def find_matching_attribute?(component_ref)
          component_ref_size = component_ref.split('/').size
          matching_attribute = nil
          
          self.component_attributes.each do |attr|
            component_name  = nil
            attr_name = attr[:display_name]
            node_name = (attr[:node]||{})[:display_name]
            
            if n_component = attr[:nested_component]
              component_name = n_component[:display_name].gsub('__','::')
            end
            
            full_name            = ''
            full_name_new_format = ''
            
            full_name << "#{node_name}/" if node_name && !node_name.eql?('assembly_wide')
            full_name_new_format << "node[#{node_name}]/" if node_name && !node_name.eql?('assembly_wide')
            
            full_name << "#{component_name}/" if component_name
            full_name_new_format << "#{component_name}/" if component_name
            
            full_name << "#{attr_name}" if attr_name
            full_name_new_format << "#{attr_name}" if attr_name
            
            if component_ref == full_name
              matching_attribute = attr
              break
            elsif component_ref == full_name_new_format
              matching_attribute = attr
              break
            end
          end
          
          matching_attribute
        end

        def propagate_hash(id, value_asserted)
          { id: id, value_asserted: value_asserted, old_value_asserted: nil }
        end

        def attribute_link(to_or_from, assembly_attribute_id, matching_attribute_id)
          input_id, output_id = (to_or_from == :to ? [matching_attribute_id, assembly_attribute_id] : [assembly_attribute_id, matching_attribute_id])
          {
            ref: "attribute_link:#{matching_attribute_id}-#{assembly_attribute_id}",
            datacenter_datacenter_id: self.target.id,
            input_id: input_id,
            output_id: output_id,
            type: 'external',
            function: 'eq'
          }
        end

      end
    end
  end
end
