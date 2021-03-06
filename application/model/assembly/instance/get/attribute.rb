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
    def get_attributes_all_levels_struct(filter_proc = nil, opts = {})
      assembly_attrs  = get_assembly_level_attributes(filter_proc, opts)
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

    def get_required_unset_attributes
      required_attributes = get_attributes_print_form(Opts.new(filter: :required_unset_attributes))
      attr_link_mh        = model_handle.createMH(:attribute_link)
      required_attributes.reject! { |r_attr| !AttributeLink.get_augmented(attr_link_mh, [:eq, :input_id, r_attr[:id]]).empty? }
      required_attributes
    end

    private

    def get_attributes_print_form_aux(opts = Opts.new)
      all_attrs = get_attributes_all_levels_struct(opts[:filter_proc], opts)
      assembly_attrs = []
      unless opts[:filter_component]
        assembly_attrs = all_attrs.assembly_attrs.map do |attr|
          attr.print_form(opts.merge(level: :assembly))
        end
      end
      component_attrs = get_component_attributes_print_form_aux(all_attrs.component_attrs, opts)
      # Assembly attributes first
      sort_attributes(assembly_attrs) + sort_attributes(component_attrs)
    end

    def get_component_attributes_print_form_aux(component_attrs, opts = Opts.new)
      # default for opts[:all] is true
      if filter_name = opts[:attribute_name]
        ret_print_form_component_attrs(filter_name(filter_name, component_attrs), opts)
      elsif filter_component = opts[:filter_component]
        # if filter component than just components that meet this filter
        ret_print_form_component_attrs(filter_components(filter_component, component_attrs), opts)
      else
        # if no filter component than all attributes
        ret_print_form_component_attrs(component_attrs, opts)
      end
    end

    def filter_name (filter, component_attrs)
      filter_component, filter_attribute = filter.split('/')
      filter_component = filter_component.gsub('::','__')
      ret = []
      component_attrs.each do |attr|
        if component = attr[:nested_component]
          ret << attr if component.display_name == filter_component && attr[:display_name] == filter_attribute
        end
      end
      ret
    end

    def filter_components(filter, component_attrs)
      # regexp_filters = filter.split(",").map do | user_friendly_componet_name|
      #   Regexp.new("^#{user_friendly_componet_name.gsub('::','__')}")
      # end
      components = filter.split(",")
      ret = []
      component_attrs.each do |attr|
        if component = attr[:nested_component]
          display_name = self.info_about(:components).find{|comp| comp[:id] == component[:id]}[:display_name]
          ret << attr if components.find { |filter_component| display_name == filter_component }
        end
      end
      ret
    end

    def ret_print_form_component_attrs(component_attrs, opts = Opts.new)
      Attribute.print_form(component_attrs, opts.merge(level: :component, assembly: self))
    end

    def sort_attributes(attributes)
      attributes.sort { |a, b| a.display_name <=> b.display_name }
    end

  end
end; end; end; end
