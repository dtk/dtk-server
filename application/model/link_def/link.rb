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
module DTK; class LinkDef
  class Link < Model
    r8_nested_require('link', 'attribute_mapping')

    def self.common_columns
      [:id, :group_id, :display_name, :remote_component_type, :position, :content, :type, :temporal_order]
    end

    def matching_attribute_mapping?(dep_attr_pattern, antec_attr_pattern)
      attribute_mappings().each do |am|
        if ret = am.match_attribute_patterns?(dep_attr_pattern, antec_attr_pattern)
          return ret
        end
      end
      nil
    end

    def add_attribute_mapping!(am_serialized_form)
      updated_attr_mappings = attribute_mappings() + [LinkDef.parse_serialized_form_attribute_mapping(am_serialized_form)]
      update_attribute_mappings!(updated_attr_mappings)
      self
    end

    # TODO: when add cardinality constraints on links, would check it here
    # assuming that augmented ports have :port_info
    def ret_matches(in_aug_port, out_aug_ports)
      ret = []
      cmp_type = self[:remote_component_type]
      out_aug_ports.each do |out_port|
        if out_port[:port_info][:component_type] == cmp_type
          match =
            case self[:type]
             when 'external'
              in_aug_port[:node_node_id] != out_port[:node_node_id]
             when 'internal'
              in_aug_port[:node_node_id] == out_port[:node_node_id]
             else
              fail Error.new('unexpected type for LinkDef::Link object')
            end
          if match
            ret << { input_port: in_aug_port, output_port: out_port }
          end
        end
      end
      ret
    end

    def self.create_from_serialized_form(link_def_idh, possible_links)
      rows = parse_possible_links(possible_links)
      link_def_id = link_def_idh.get_id()
      rows.each_with_index do |r, i|
        r[:position] = i + 1
        r[:link_def_id] = link_def_id
      end
      create_from_rows(model_handle, rows)
    end

    # craetes attribute links and can clone if needed attributes on a service node group to its members

    def update_attribute_mappings!(new_attribute_mappings)
      ret = self[:attribute_mappings] = new_attribute_mappings
      self[:content] ||= {}
      self[:content][:attribute_mappings] = ret
      update({ content: self[:content] }, convert: true)
      ret
    end

    def attribute_mappings
      # TODO: may convert to using @attribute_mappings; need to make sure no side-effects
      self[:attribute_mappings] ||= (self[:content][:attribute_mappings] || []).map { |am| AttributeMapping.reify(am) }
    end

    def on_create_events
      self[:on_create_events] ||= ((self[:content][:events] || {})[:on_create] || []).map { |ev| Event.create(ev, self) }
    end

    class Event < HashObject
      def self.create(event, link_def_link)
        case event[:event_type]
          when 'extend_component' then EventExtendComponent.new(event, link_def_link)
          else
            fail Error.new('unexpecetd event type')
        end
      end
      def process!(_context)
        fail Error.new('Needs to be overwritten')
      end
    end

    class EventExtendComponent < Event
      def initialize(event, link_def_link)
        base_cmp = link_def_link[event[:node] == 'remote' ? :remote_component_type : :local_component_type]
        super(event.merge(base_component: base_cmp))
      end

      def process!(context)
        fail Error.new('deprecated context.find_component')
        # base_component = context.find_component(self[:base_component])
        fail Error.new("cannot find component with ref #{self[:base_component]} in context") unless base_component
        component_extension = base_component.get_extension_in_library(self[:extension_type])
        fail Error.new("cannot find library extension of type #{self[:extension_type]} to #{self[:base_component]} in library") unless component_extension

        # find node to clone it into
        node = (self[:node] == 'local') ? context.local_node : context.remote_node
        fail Error.new("cannot find node of type #{self[:node]} in context") unless node

        # clone component into node
        override_attrs = { from_on_create_event: true }
        # TODO: may put in flags to tell clone operation not to do any constraint checking
        clone_opts = { ret_new_obj_with_cols: [:id, :display_name, :extended_base, :implementation_id] }
        new_cmp = node.clone_into(component_extension, override_attrs, clone_opts)

        # if alias is given, update context to reflect this
        if self[:alias]
          context.add_component_ref_and_value!(self[:alias], new_cmp)
        end
      end

      private

      def validate_top_level(hash)
        fail Error.new('node is set incorrectly') if hash[:node] and not [:local, :remote].include?(hash[:node].to_sym)
        fail Error.new('no extension_type is given') unless hash[:extension_type]
      end
    end
  end
end; end