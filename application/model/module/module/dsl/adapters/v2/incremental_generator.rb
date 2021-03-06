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
module DTK; class ModuleDSL; class V2
  class IncrementalGenerator < ModuleDSL::IncrementalGenerator
    private

    def component
      Component
    end
    class Component < self
      def self.display_name_print_form(cmp_type)
        ::DTK::Component.display_name_print_form(cmp_type)
      end
      def self.get_fragment(full_hash, cmp_type)
        unless ret = (full_hash['components'] || {})[hash_index(cmp_type)]
          fail Error.new("Cannot find component (#{display_name_print_form(cmp_type)})")
        end
        ret
      end

      private

      def self.hash_index(cmp_type)
        ::DTK::Component.display_name_print_form(cmp_type, no_module_name: true)
      end
    end

    class Attribute < self
      def generate(attr)
        # TODO: treat default and external_ref
        attr.object.update_object!(:display_name, :description, :data_type, :semantic_type, :required, :dynamic, :external_ref)
        ref = attr.required(:display_name)
        content = PrettyPrintHash.new
        set?(:description, content, attr)
        type = type(attr[:data_type], attr[:semantic_type])
        content['type'] = type if type
        content['required'] = true if attr[:required]
        content['dynamic'] = true if attr[:dynamic]
        { ref => content }
      end

      def merge_fragment!(full_hash, fragment, context = {})
        component_fragment = component_fragment(full_hash, context[:component_template])
        if attributes_fragment = component_fragment['attributes']
          fragment.each do |key, content|
            update_attributes_fragment!(attributes_fragment, key, content)
          end
        else
          component_fragment['attributes'] = fragment
        end
        full_hash
      end

      private

      def type(data_type, semantic_type)
        ret = data_type
        if semantic_type
          unless semantic_type.is_a?(Hash) && semantic_type.size == 1 && semantic_type.keys.first == ':array'
            Log.error("Ignoring because unexpected semantic type (#{semantic_type})")
          else
            ret = "array(#{semantic_type.values.first})"
          end
        end
        ret || 'string'
      end

      def update_attributes_fragment!(attributes_fragment, key, content)
        (attributes_fragment[key] ||= {}).merge!(content)
      end
    end

    class LinkDef < self
      def generate(aug_link_def)
        ref = aug_link_def.required(:link_type)
        link_def_links = aug_link_def.required(:link_def_links)
        if link_def_links.empty?
          fail Error.new('Unexpected that link_def_links is empty')
        end
        opts_choice = {}
        if single_choice = (link_def_links.size == 1)
          opts_choice.merge!(omit_component_ref: ref)
        end
        possible_links = aug_link_def[:link_def_links].map do |link_def_link|
          choice_info(aug_link_def, ObjectWrapper.new(link_def_link), opts_choice)
        end
        content = (single_choice ? possible_links.first : { 'choices' => possible_links })
        { ref => content }
      end

      def merge_fragment!(full_hash, fragment, context = {})
        component_fragment = component_fragment(full_hash, context[:component_template])
        if depends_on_fragment = component_fragment['depends_on']
          fragment.each do |key, content|
            update_depends_on_fragment!(depends_on_fragment, key, content)
          end
        else
          component_fragment['depends_on'] = [fragment]
        end
        full_hash
      end

      private

      def update_depends_on_fragment!(depends_on_fragment, key, content)
        depends_on_fragment.each_with_index do |depends_on_el, i|
          if (depends_on_el.is_a?(Hash) && depends_on_el.keys.first == key) ||
              (depends_on_el.is_a?(String) && depends_on_el == key)
            depends_on_fragment[i] = { key => content }
            return
          end
        end
        depends_on_fragment << { key => content }
      end

      def choice_info(_link_def, link_def_link, opts = {})
        ret = PrettyPrintHash.new
        remote_cmp_type = link_def_link.required(:remote_component_type)
        cmp_ref = Component.display_name_print_form(remote_cmp_type)
        unless opts[:omit_component_ref] == cmp_ref
          ret['component'] = cmp_ref
        end
        location =
          case link_def_link.required(:type)
            when 'internal' then 'local'
            when 'external' then 'remote'
            else fail new Error.new("unexpected value for type (#{link_def_link.required(:type)})")
          end
        ret['location'] = location
        if (not link_def_link[:required].nil?) and not link_def_link[:required]
          ret['required'] = false
        end
        ams = link_def_link.object.attribute_mappings()
        if ams and not ams.empty?
          ret['attribute_mappings'] = ams.map { |am| attribute_mapping(ObjectWrapper.new(am), remote_cmp_type) }
        end
        ret
      end

      def attribute_mapping(am, remote_cmp_type)
        input_attr, input_is_remote = mapping_attribute(:input, am, remote_cmp_type)
        output_attr, output_is_remote = mapping_attribute(:output, am, remote_cmp_type)
        if (!input_is_remote) && (!output_is_remote)
          fail Error.new('Cannot determine attribute mapping direction; both do not match remote component type')
        elsif input_is_remote && output_is_remote
          fail Error.new('Cannot determine attribute mapping direction; both match remote component type')
        elsif (!input_is_remote) && output_is_remote
          "$#{output_attr} -> #{input_attr}"
        else #input_is_remote and (!output_is_remote)
          "#{input_attr} <- $#{output_attr}"
        end
      end

      def mapping_attribute(input_or_output, am, remote_cmp_type)
        var = ObjectWrapper.new(am.required(input_or_output))
        case var.required(:type)
          when 'component_attribute' then mapping_attribute__component_type(var, remote_cmp_type)
          when 'node_attribute' then mapping_attribute__node_type(var)
          else fail Error.new("Unexpected mapping-attribute type (#{var.required(:var)})")
        end
      end

      def mapping_attribute__component_type(var, remote_cmp_type)
        split = var.required(:term_index).split('.')
        unless split.size == 2
          fail Error.new("Not yet implemented: treating component mapping-attribute of form (#{var.required(:term_index)})")
        end
        attr = var.required(:attribute_name)
        [attr, var.required(:component_type) == remote_cmp_type]
      end

      def mapping_attribute__node_type(var)
        if ['host_address', 'host_addresses_ipv4'].include?(var.required(:attribute_name))
          attr = 'node.host_address'
          [attr, var.required(:node_name) == 'remote']
        else
          fail Error.new("Not yet implemented: treating node mapping-attribute of form (#{var.required(:term_index)})")
        end
      end
    end
  end
end; end; end