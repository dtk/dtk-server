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
module DTK; class Node
  class NodeAttribute
    module Mixin
      def attribute
        NodeAttribute.new(self)
      end

      def get_node_attribute?(attribute_name, opts = {})
        get_node_attributes(opts.merge(filter: [:eq, :display_name, attribute_name])).first
      end

      def get_node_attributes(opts = {})
        Node.get_node_level_attributes([id_handle()], cols: opts[:cols], add_filter: opts[:filter])
      end

      # TODO: stub; see if can use get_node_attributes
      def get_node_attributes_stub
        []
      end
      # TODO: once see calling contex, remove stub call
      def get_node_and_component_attributes(_opts = {})
        node_attrs = get_node_attributes_stub()
        component_attrs = get_objs(cols: [:component_attrs]).map { |r| r[:attribute] }
        component_attrs + node_attrs
      end

      def set_attributes(av_pairs)
        Attribute::Pattern::Node.set_attributes(self, av_pairs)
      end

      def get_attributes_print_form(opts = {})
        if filter = opts[:filter]
          case filter
          when :required_unset_attributes
            get_attributes_print_form_aux(lambda { |a| a.required_unset_attribute?() })
          else
            fail Error.new("not treating filter (#{filter}) in Assembly::Instance#get_attributes_print_form")
          end
        else
          get_attributes_print_form_aux()
        end
      end

      def get_attributes_print_form_aux(filter_proc = nil)
        node_attrs = get_node_attributes_stub()
        component_attrs = get_objs(cols: [:component_attrs]).map do |r|
          attr = r[:attribute]
          # TODO: more efficient to have sql query do filtering
          if filter_proc.nil? || filter_proc.call(attr)
            display_name_prefix = "#{r[:component].display_name_print_form()}/"
            attr.print_form(Opts.new(display_name_prefix: display_name_prefix))
          end
        end.compact
        (component_attrs + node_attrs).sort { |a, b| a[:display_name] <=> b[:display_name] }
      end
      private :get_attributes_print_form_aux

      def get_virtual_attribute(attribute_name, cols, field_to_match = :display_name)
        sp_hash = {
          model_name: :attribute,
          filter: [:eq, field_to_match, attribute_name],
          cols: cols
        }
        get_children_from_sp_hash(:attribute, sp_hash).first
      end
      # TODO: may write above in terms of below
      def get_virtual_attributes(attribute_names, cols, field_to_match = :display_name)
        sp_hash = {
          model_name: :attribute,
          filter: [:oneof, field_to_match, attribute_names],
          cols: Aux.array_add?(cols, field_to_match)
        }
        get_children_from_sp_hash(:attribute, sp_hash)
      end

      # attribute on component on node
      # assumption is that component cannot appear more than once on node
      def get_virtual_component_attribute(cmp_assign, attr_assign, cols)
        base_sp_hash = {
          model_name: :component,
          filter: [:and, [:eq, cmp_assign.keys.first, cmp_assign.values.first], [:eq, :node_node_id, self[:id]]],
          cols: [:id]
        }
        join_array =
          [{
             model_name: :attribute,
             convert: true,
             join_type: :inner,
             filter: [:eq, attr_assign.keys.first, attr_assign.values.first],
             join_cond: { component_component_id: :component__id },
             cols: cols.include?(:component_component_id) ? cols : cols + [:component_component_id]
           }]
        row = Model.get_objects_from_join_array(model_handle.createMH(:component), base_sp_hash, join_array).first
        row && row[:attribute]
      end

      ####Things below heer shoudl be cleaned up or deprecated
      #####
      # TODO: should be centralized
      def get_contained_attribute_ids(_opts = {})
        get_directly_contained_object_ids(:attribute) || []
      end

      def get_direct_attribute_values(type, _opts = {})
        parent_id = IDInfoTable.get_id_from_id_handle(id_handle)
        attr_val_array = Model.get_objects(ModelHandle.new(@c, :attribute), nil, parent_id: parent_id)
        return nil if attr_val_array.nil?
        return nil if attr_val_array.empty?
        hash_values = {}
        attr_type = { asserted: :value_asserted, derived: :value_derived, value: :attribute_value }[type]
        attr_val_array.each do|attr|
          hash_values[attr.get_qualified_ref.to_sym] =
          { value: attr[attr_type], id: attr[:id] }
        end
        { attribute: hash_values }
      end

      private

      def check_and_ret_title_attribute_name?(component_template, component_title)
        title_attr_name = component_template.get_title_attribute_name?()
        if component_title && title_attr_name.nil?
          fail ErrorUsage.new("Component (#{component_template.component_type_print_form()}) is given a title, but should not have one")
        elsif component_title.nil? && title_attr_name
          cmp_name = component_template.component_type_print_form()
          fail ErrorUsage.new("Component (#{cmp_name}) needs a title; use form #{cmp_name}[TITLE]")
        end
        title_attr_name
      end
    end
  end
end; end
