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
module DTK; class Assembly; class Instance; module Get
  module AttributeMixin
    def get_attributes_print_form(opts = {})
      if filter = opts[:filter]
        case filter
          when :required_unset_attributes
            opts.merge!(filter_proc: FilterProc)
          else
            fail Error.new("not treating filter (#{filter}) in Assembly::Instance#get_attributes_print_form")
        end
      end
      get_attributes_print_form_aux(opts)
    end
    FilterProc = lambda do |r|
      attr =
        if r.is_a?(Attribute) then r
        elsif r[:attribute] then r[:attribute]
        else fail Error.new("Unexpected form for filtered element (#{r.inspect})")
        end
      attr.required_unset_attribute?()
    end

    def get_attributes_all_levels
      assembly_attrs = get_assembly_level_attributes
      node_attrs, component_attrs = get_augmented_node_and_component_attributes
      assembly_attrs + component_attrs + node_attrs
    end

    AttributesAllLevels = Struct.new(:assembly_attrs, :component_attrs, :node_attrs)
    def get_attributes_all_levels_struct(filter_proc = nil)
      assembly_attrs = get_assembly_level_attributes(filter_proc)
      node_attrs, component_attrs = get_augmented_node_and_component_attributes(filter_proc)
      # TODO: The pruning below might go in get_augmented_node_and_component_attributes
      # Don't add component_attrs by default
      component_attrs.reject! do |attr|
        (not attr[:nested_component].get_field?(:only_one_per_node)) && attr.is_title_attribute?()
      end
      AttributesAllLevels.new(assembly_attrs, component_attrs, node_attrs)
    end

    # returns [node_attrs, component_attrs]
    def get_augmented_node_and_component_attributes(filter_proc = nil)
      node_attrs = get_objs_helper(:node_attributes, :attribute, filter_proc: filter_proc, augmented: true)

      # DTK-2536; For issues 1 and 2, we should get rid of os_identifier
      node_attrs.delete_if{|attr| attr[:display_name].eql?('os_identifier')}

      component_attrs = get_objs_helper(:instance_nested_component_attributes, :attribute, filter_proc: filter_proc, augmented: true) 
      move_node_components_to_node_attrs!(node_attrs, component_attrs)
      [node_attrs, component_attrs]
    end

    private

    # moves component_attrs that are node property components to node_attrs
    def move_node_components_to_node_attrs!(node_attrs, component_attrs)
      # TODO: unify with Attribute::PrintForm.convert_if_node_component!
      node_cmp_types = CommandAndControl.node_property_component_names.map { |n| n.gsub(/::/,'__') }
      component_attrs.reject! do |aug_attr|
        if node_cmp_types.include?(aug_attr[:nested_component][:component_type])
          # check if this attribute is already a node attribute
          # TODO: DTK-2489: donthave these in two places
          name = aug_attr[:display_name]
          node_id = aug_attr[:node][:id]

          # give precedence to component attributes over node
          if n_attr = node_attrs.find { |node_attr| node_attr[:display_name] == name and node_attr[:node][:id] == node_id }
            aug_attr.delete(:nested_component)
            node_attrs.delete(n_attr)
            node_attrs << aug_attr
          else
            # delete :nested_component key to make this a node attribute and put in noe attribute list
            aug_attr.delete(:nested_component) 
            node_attrs << aug_attr
          end
          true # true so gets deleted if node_cmp_types contains aug_attr
        end
      end
    end

    def filter_component(filter_component, all_attrs)
      ret = []
      filter_component = filter_component.split(",")

      all_attrs.component_attrs.each do |attr|
        unless attr[:nested_component].nil? 
          filter_component.each do |cmp| 
            if attr[:nested_component][:display_name].include?(cmp.gsub('::','__'))
              ret << attr
            end
          end
        end
      end
      ret
    end

    def ret_print_form_component_attrs(component_attrs, opts)
      opts_attr = opts.merge(level: :component, assembly: self)
      component_attrs = Attribute.print_form(component_attrs, opts_attr)
    end

    def get_attributes_print_form_aux(opts = Opts.new)
      filter_proc = opts[:filter_proc]
      filter_component = opts[:filter_component]
      all_attrs = get_attributes_all_levels_struct(filter_proc)
      node_attrs      = []
      component_attrs = []

      # remove all assembly_wide_node attributes
      all_attrs.node_attrs.reject! { |r| r[:node] && Node.is_assembly_wide_node?(r[:node]) }

      filter_proc = opts[:filter_proc]
      assembly_attrs = all_attrs.assembly_attrs.map do |attr|
        attr.print_form(opts.merge(level: :assembly))
      end

      unless (filter_component||"").empty?
        filtered_component_attrs = filter_component(filter_component, all_attrs) 
        component_attrs = ret_print_form_component_attrs(filtered_component_attrs, opts)
        assembly_attrs  = []
        #TODO: temporary set to false 
        opts[:all] = false
      end

      if opts[:all]
        component_attrs = ret_print_form_component_attrs(all_attrs.component_attrs, opts)
        node_attrs = all_attrs.node_attrs.map do |aug_attr|
            aug_attr.print_form(opts.merge(level: :node))
        end
      end
      (assembly_attrs + node_attrs + component_attrs).sort { |a, b| a[:display_name] <=> b[:display_name] }
    end
  end
end; end; end; end
