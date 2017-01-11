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
  class ObjectLogic::Assembly
    class Component::Diff
      class Add < CommonDSL::Diff::Element::Add
        include Mixin

        def process(result, opts = {})
          aug_cmp_template = nil
          begin 
            aug_cmp_template = assembly_instance.find_matching_aug_component_template(module_name, component_type, component_module_refs(opts))
          rescue ErrorUsage => e
            aug_cmp_template = nil
            result.add_error_msg(e.message)
          end
          return unless  aug_cmp_template

          node = parent_node? || assembly_instance.create_assembly_wide_node?
          new_component_idh = add_component_to_node(node, aug_cmp_template, component_title: component_title?)
          
          result.add_item_to_update(:workflow) # workflow will be updated with spliced in new component
          result.add_item_to_update(:assembly) # this is to account for fact that when component is added, default attributes will also be added
          
          # any attributes that all in diff are overrides that subsume the component's default attributes
          set_attribute_overrides(result, new_component_idh)
        end
        
        private

        def module_name 
          @module_name ||= ::DTK::Component.module_name_from_user_friendly_name(component_name)
        end
        
        def component_type 
          @component_type ||= ::DTK::Component.component_type_from_user_friendly_name(component_name)
        end

        # opts can have keys:
        #   :component_title
        def add_component_to_node(node, aug_cmp_template, opts = {})
          assembly_instance.add_component(node.id_handle, aug_cmp_template, opts[:component_title])
        end
        
        def set_attribute_overrides(result, new_component_idh)
          return if attributes_semantic_parse_hash.empty?
          
          ndx_existing_attributes = ndx_existing_component_attributes(new_component_idh, attributes_semantic_parse_hash.keys)

          attributes_semantic_parse_hash.each do |attr_name, attr_content|
            unless existing_attribute = ndx_existing_attributes[attr_name]
              Diff::DiffErrors.raise_error(error_msg: "Invalid attribute '#{attr_name}' is provided for component '#{qualified_key.print_form}'")
            end
            existing_attr_value = existing_attribute.get_field?(:attribute_value)
            new_attr_value      = attr_content.req(:Value)
            find_diff_opts      = {
              qualified_key: qualified_key.create_with_new_element?(:attribute, attr_name),
              id_handle: existing_attribute.id_handle,
              service_instance: @service_instance
            }
            if base_attribute_diff = Diff::Base.diff?(existing_attr_value, new_attr_value, find_diff_opts)
              attribute_add_diff = Attribute::Diff::Modify.new(base_attribute_diff)
              attribute_add_diff.process(result)
            end
          end
        end
        
        # Returns attribute values indexed by attribute name
        def ndx_existing_component_attributes(component_idh, attr_names)
          ret = {}

          (component_idh.create_object.get_attributes || []).each do |cmp_attribute|
            cmp_attr_name = cmp_attribute[:display_name]
            ret.merge!(cmp_attr_name => cmp_attribute) if attr_names.include?(cmp_attr_name)
          end

          ret
        end
        
        def attributes_semantic_parse_hash
          @attributes_semantic_parse_hash ||= @parse_object.val(:Attributes) || {}
        end

      end
    end
  end
end; end
