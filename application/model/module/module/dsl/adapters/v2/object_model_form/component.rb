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
# TODO: this does some conversion of form; should determine what shoudl be done here versus subsequent parser phase
# TODO: does not check for extra attributes
module DTK; class ModuleDSL; class V2
  class ObjectModelForm
    class Component < self
      include ComponentChoiceMixin
      def initialize(module_name)
        @module_name = module_name
      end
      
      def convert(input_hash, context = {})
        (input_hash || {}).inject(OutputHash.new) { |h, (k, v)| h.merge(key(k) => body(v, k, context)) }
      end
      
      private
      
      def key(input_key)
        qualified_component(input_key)
      end
      
      def qualified_component(cmp)
        if @module_name == cmp
          cmp
        else
          "#{@module_name}#{ModCmpDelim}#{cmp}"
        end
      end
      
      def body(input_hash, cmp, _context = {})
        ret = OutputHash.new
        cmp_type = ret['display_name'] = ret['component_type'] = qualified_component(cmp)
        ret['basic_type'] = 'service'
        ret.set_if_not_nil('description', input_hash['description'])
        external_ref = external_ref(input_hash.req(:external_ref), cmp)
        ret['external_ref'] = external_ref
        ret.set_if_not_nil('only_one_per_node', only_one_per_node(external_ref))
        add_attributes!(ret, cmp_type, input_hash)
        opts = {}
        add_dependent_components!(ret, input_hash, cmp_type, opts)
        ret.set_if_not_nil('component_include_module', include_modules?(input_hash['include_modules']))
        if opts[:constants]
          add_attributes!(ret, cmp_type, ret_input_hash_with_constants(opts[:constants]), constant_attribute: true)
        end
        ret
      end

      def ret_input_hash_with_constants(constant_assigns)
        attrs_hash = constant_assigns.inject(InputHash.new) do |h, ca|
          el = { ca.attribute_name() => {
              'type' => ca.datatype() || 'string',
              'default' => ca.attribute_value()
            }.merge(Attribute::Constant.side_effect_settings())
          }
          h.merge(el)
        end
        InputHash.new('attributes' => attrs_hash)
      end

      def external_ref(input_hash, cmp)
        fail ParsingError.new('Component (?1) external_ref is ill-formed (?2)', cmp, input_hash) unless input_hash.is_a?(Hash) and input_hash.size == 1

        type = input_hash.keys.first
        name_key =
          case type
            when 'puppet_class' then 'class_name'
            when 'puppet_definition' then 'definition_name'
            when 'serverspec_test' then 'test_name'
            else fail ParsingError.new('Component (?1) external_ref has illegal type (?2)', cmp, type)
          end
        name = input_hash.values.first
        OutputHash.new('type' => type, name_key => name)
      end

      def only_one_per_node(external_ref)
        external_ref['type'] != 'puppet_definition'
      end

      def include_modules?(incl_module_array, context = {})
        return nil if incl_module_array.nil?
        incl_module_array = [incl_module_array] if incl_module_array.is_a?(String)
        unless incl_module_array.is_a?(Array)
          err_params = ParsingError::Params.new(incl_module_array: incl_module_array, section: context[:section_name] || 'include_modules')
          err_msg = "The content in the '?section' section"
          if cmp_type = context[:component_type]
            cmp_name = component_print_form(cmp_type)
            err_params.merge!(component_name: cmp_name)
            err_msg += ' under component (?component_name)'
          end
          err_msg += ' is ill-formed: ?incl_module_array'
          fail ParsingError.new(err_msg, err_params)
        end
        ret = OutputHash.new
        incl_module_array.each do |incl_module|
          el =
            if incl_module.is_a?(String)
              { 'display_name' => incl_module }
            elsif incl_module.is_a?(Hash)
              hash = hash_contains?(incl_module, ['*module', 'version'])
              version_constraint = include_module_version_constraint(hash['version'])
              { 'display_name' => hash['module'], 'version_constraint' => version_constraint }
            end
          unless el
            fail ParsingError.new('The include_module element (?1) is ill-formed', incl_module)
          end
          ref = el['display_name']
          ret.merge!(ref => el)
        end
        ret
      end

      def combine_includes(more_specific_incls, less_specific_incls)
        if more_specific_incls.nil?
          less_specific_incls
        elsif less_specific_incls.nil?
          more_specific_incls
        else
          less_specific_incls.merge(more_specific_incls)
        end
      end

      IncludeModVersionOps = ['>=']
      IncludeModVersionNumRegexp = /^[0-9]+\.[0-9]+\.[0-9]+/
      def include_module_version_constraint(version)
        no_error =
          if version.is_a?(String)
            if version =~ IncludeModVersionNumRegexp
              true
            end
          elsif version.is_a?(Array)
            if version.size == 2 && IncludeModVersionOps.include?(version[0]) && version[1] =~ IncludeModVersionNumRegexp
              true
            end
          end
        unless no_error
          fail ParsingError.new('The include_modules version key (?1) is ill-formed', version)
        end
        version
      end

      def add_attributes!(ret, cmp_type, input_hash, opts = {})
        unless in_attrs = input_hash['attributes']
          return ret
        end

        ParsingError.raise_error_if_not(in_attrs, Hash)

        attrs = OutputHash.new
        in_attrs.each_pair do |attr_name, attr_info|
          if attr_info.is_a?(Hash)
            opts_attr = { component_type: cmp_type }.merge(opts)
            attrs[attr_name] = attribute_fields(attr_name, attr_info, opts_attr)
          else
            cmp_name = component_print_form(cmp_type)
            fail ParsingError.new('Ill-formed attributes section for component (?1): ?2', cmp_name, 'attributes' => in_attrs)
          end
        end

        if ret['attribute']
          ret['attribute'].merge!(attrs)
        else
          ret['attribute'] = attrs
        end
        ret
      end

      # partitions into link_defs, "dependency", and "component_order"
      def add_dependent_components!(ret, input_hash, base_cmp, opts = {})
        dep_config = get_dependent_config(input_hash, base_cmp, opts)
        ret.set_if_not_nil('dependency', dep_config[:dependencies])
        ret.set_if_not_nil('component_order', dep_config[:component_order])
        ret.set_if_not_nil('link_defs', dep_config[:link_defs])
      end

      def get_dependent_config(input_hash, base_cmp, opts = {})
        ret = {}
        link_defs  = []
        if in_dep_cmps = input_hash['depends_on']
          convert_to_hash_form(in_dep_cmps) do |conn_ref, conn_info|
            choices = choice().convert_choices(conn_ref, conn_info, base_cmp, opts)

            # determine if create a link def and/or a dependency
            # creaet a dependency if just single choice and base adn depnedncy on same node
            # TODO: only handling addition of dependencies if single choice; consider adding just temporal if multiple choices
            if choices.size == 1
              choice = choices.first
              if choice.is_internal?()
                pntr = ret[:dependencies] ||= OutputHash.new
                add_dependency!(pntr, choice.dependent_component(), base_cmp)
              end
            end

            # create link defs if there are multiple choices or theer are attribute mappings
            if choices.size > 1 || (choices.size == 1 && choices.first.has_attribute_mappings?())
              link_def = OutputHash.new(
                'type' => get_connection_label(conn_ref, conn_info),
                'required' =>  true, #will be putting optional elements under a key that is peer to 'depends_on'
                'possible_links' => choices.map(&:possible_link)
              )
              link_def.set_if_not_nil('description', conn_info['description'])
              link_defs << link_def
            end
          end
        end
        ret[:link_defs] = link_defs unless link_defs.empty?
        # TODO: is this redundant with 'order', which just added
        if component_order = component_order(input_hash)
          ret[:component_order] = component_order
        end
        ret
      end

      def get_connection_label(conn_ref, conn_info)
        # if component key given then conn_ref will be connection label
        # if there are choices then conn_ref will be connection label
        # otherwise conn_ref will be component ref and we use the component part for the conenction label
        if conn_info['component'] || conn_info['choices']
          conn_ref
        else
          cmp_external_form = conn_ref
          cmp_external_form
        end
      end
    end
  end
end; end; end
