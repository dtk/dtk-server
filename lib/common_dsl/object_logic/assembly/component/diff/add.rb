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
          matching_aug_cmp_templates = ::DTK::Component::Template.find_matching_component_templates(assembly_instance, component_name) 
          aug_cmp_template = nil

          if matching_aug_cmp_templates.empty?
            result.add_error_msg("Component '#{qualified_key.print_form}' does not match any installed component templates")
          elsif matching_aug_cmp_templates.size > 1
            # TODO: DTK-2665:  put in message the name of matching component templates
            aug_cmp_template = find_matching_dependency(matching_aug_cmp_templates, opts[:dependent_modules])

            unless aug_cmp_template
              error_msg = "Component '#{qualified_key.print_form}' matches multiple installed component templates. Please select one of the following templates by adding under dependencies key inside 'dtk.service.yaml' file:"
              error_msg += "\n#{pretty_print_templates(matching_aug_cmp_templates).join(",\n")}"
              result.add_error_msg(error_msg)
            end
          else
            aug_cmp_template = matching_aug_cmp_templates.first
          end
          
          if aug_cmp_template
            node = parent_node? || assembly_instance.create_assembly_wide_node?
            new_component_idh = add_component_to_node(node, aug_cmp_template, component_title: component_title?)
            result.add_item_to_update(:workflow) # workflow will be updated with spliced in new component
            result.add_item_to_update(:assembly) # this is to account for fact that when component is added, default attributes will also be added
            # any attributes that all in diff are overrides that subsume the component's default attributes
            set_attribute_overrides(result, new_component_idh)
            # raise 'got here'
          end 
        end
        
        private

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
              # TODO: 2650: raise error indicating that an invalid attribute is given; indicate error by using qualified_key.printname and name of attribute
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
          # TODO: 2650: write code that looks up on component_idh to get all attributes on this component that match a name in attr_names
        end
        
        def attributes_semantic_parse_hash
          @attributes_semantic_parse_hash ||= @parse_object.val(:Attributes) || {}
        end
        
        def find_matching_dependency(matching_aug_cmp_templates, dependencies = {})
          return if dependencies.empty?
          
          ret = nil
          dependencies.each do |name, version|
            ret = match_templates_against_dependency(matching_aug_cmp_templates, name, version)
            break if ret
          end
          
          ret
        end
        
        def match_templates_against_dependency(templates, dep_name, dep_version = 'master')
          templates.find{ |template| "#{template[:namespace][:display_name]}/#{template[:display_name]}".eql?(dep_name) && template[:version].eql?(dep_version) }
        end
        
        def pretty_print_templates(templates)
          temp_array = []
          
          templates.each do |template|
            temp_array << "#{template[:namespace][:display_name]}/#{template[:display_name]}: #{template[:version]}"
          end
          
          temp_array
        end
        
      end
    end
  end
end; end
