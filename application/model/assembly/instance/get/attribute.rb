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
      assembly_attrs  = get_assembly_level_attributes
      component_attrs = get_augmented_component_attributes
      assembly_attrs + component_attrs
    end

    AttributesAllLevels = Struct.new(:assembly_attrs, :component_attrs)
    def get_attributes_all_levels_struct(filter_proc = nil)
      assembly_attrs = get_assembly_level_attributes(filter_proc)
      component_attrs = get_augmented_component_attributes(filter_proc)
      # TODO: The pruning below might go in get_augmented_component_attributes
      component_attrs.reject! do |attr|
        (not attr[:nested_component].get_field?(:only_one_per_node)) && attr.is_title_attribute?()
      end
      AttributesAllLevels.new(assembly_attrs, component_attrs)
    end

    def get_augmented_component_attributes(filter_proc = nil)
      get_objs_helper(:instance_nested_component_attributes, :attribute, filter_proc: filter_proc, augmented: true) 
    end

    private

    def get_attributes_print_form_aux(opts = Opts.new)
      filter_proc = opts[:filter_proc]
      all_attrs = get_attributes_all_levels_struct(filter_proc)

      filter_proc = opts[:filter_proc]
      assembly_attrs = all_attrs.assembly_attrs.map do |attr|
        attr.print_form(opts.merge(level: :assembly))
      end

      opts_attr = opts.merge(level: :component, assembly: self)
      component_attrs = Attribute.print_form(all_attrs.component_attrs, opts_attr)

      # Assembly attributes first
      sort_attributes(assembly_attrs) + sort_attributes(component_attrs)
    end

    def sort_attributes(attributes)
      attributes.sort { |a, b| a.display_name <=> b.display_name }
    end

  end
end; end; end; end
