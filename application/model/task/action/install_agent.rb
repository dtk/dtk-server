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
module DTK; class Task
class Action
  class InstallAgent < PhysicalNode
      def initialize(type, object, task_idh = nil, _assembly_idh = nil)
        hash =
          case type
           when :state_change
            {
              state_change_id: object[:id],
              state_change_types: [object[:type]],
              attributes: [],
              node: node_create_obj_optional_subclass(object[:node]),
              datacenter: object[:datacenter],
              user_object: CurrentSession.new.get_user_object()
            }
           when :hash
            object
           else
            fail Error.new('Unexpected InstallAgent.initialize type')
          end
        super(type, hash, task_idh)
      end
      private :initialize

      def self.status(object, opts)
        ret = PrettyPrintHash.new
        ret[:node] = node_status(object, opts)
        ret
      end

      # for debugging
      def self.pretty_print_hash(object)
        ret = PrettyPrintHash.new
        ret[:node] = (object[:node] || {})[:display_name]
        ret
      end

      def get_dynamic_attributes(_result)
        ret = []
        # attrs_to_set = attributes_to_set()
        # attr_names = attrs_to_set.map{|a|a[:display_name].to_sym}
        # av_pairs__node_components = get_dynamic_attributes__node_components!(attr_names)
        # rest_av_pairs = (attr_names.empty? ? {} : CommandAndControl.get_and_update_node_state!(self[:node],attr_names))
        # av_pairs = av_pairs__node_components.merge(rest_av_pairs)
        # return ret if av_pairs.empty?
        # attrs_to_set.each do |attr|
        #   attr_name = attr[:display_name].to_sym
        #   #TODO: can test and case here whether value changes such as wehetehr new ip address
        #   attr[:attribute_value] = av_pairs[attr_name] if av_pairs.has_key?(attr_name)
        #   ret << attr
        # end
        ret
      end

      ###special processing for node_components
      def get_dynamic_attributes__node_components!(_attr_names)
        ret = {}
        # return ret unless attr_names.delete(:node_components)
        # #TODO: hack
        # ipv4_val = CommandAndControl.get_and_update_node_state!(self[:node],[:host_addresses_ipv4])
        # return ret if ipv4_val.empty?
        # cmps = self[:node].get_objs(:cols => [:components]).map{|r|r[:component][:display_name].gsub("__","::")}
        # ret = {:node_components => {ipv4_val.values.first[0] => cmps}}
        # if attr_names.delete(:host_addresses_ipv4)
        #   ret.merge!(ipv4_val)
        # end
        ret
      end

      def add_attribute!(attr)
        self[:attributes] << attr
      end

      def attributes_to_set
        self[:attributes].reject { |a| not a[:dynamic] }
      end

      def ret_command_and_control_adapter_info
        [:node_config, :ssh]
      end

      def update_state_change_status(task_mh, status)
        # no op if no associated state change
        if self[:state_change_id]
          update_state_change_status_aux(task_mh, status, [self[:state_change_id]])
        end
      end

      def self.add_attributes!(attr_mh, action_list)
        ndx_actions = {}
        action_list.each { |a| ndx_actions[a[:node][:id]] = a }
        return nil if ndx_actions.empty?

        parent_field_name = DB.parent_field(:node, :attribute)
        sp_hash = {
          cols: [:id, :group_id, :display_name, parent_field_name, :external_ref, :attribute_value, :required, :dynamic],
          filter: [:and,
                   [:eq, :dynamic, true],
                   [:oneof, parent_field_name, ndx_actions.keys]]
        }

        attrs = Model.get_objs(attr_mh, sp_hash)

        attrs.each do |attr|
          action = ndx_actions[attr[parent_field_name]]
          action.add_attribute!(attr)
        end
      end

      def create_node_config_agent_type
        self[:config_agent_type]
      end

    private

      def self.node_status(object, _opts)
        node = object[:node] || {}
        ext_ref = node[:external_ref] || {}
        kv_array =
          [{ name: node_status__name(node) },
           { id: node[:id] },
           { type: ext_ref[:type] },
           { image_id: ext_ref[:image_id] },
           { size: ext_ref[:size] }
          ]
        PrettyPrintHash.new.set?(*kv_array)
      end
    end
  end
end; end
