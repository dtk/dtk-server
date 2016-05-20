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
  class Action < HashObject
    def type
      Aux.underscore(Aux.demodulize(self.class.to_s)).to_sym
    end

    # implemented functions
    def long_running?
      nil
    end

    # returns [adapter_type,adapter_name], adapter name optional in which it wil be looked up from config
    def ret_command_and_control_adapter_info
     nil
    end

    class OnNode < self
      def self.create_from_node(node)
        state_change = { node: node }
        new(:state_change, state_change, nil)
      end
      def self.create_from_state_change(state_change, assembly_idh = nil)
        new(:state_change, state_change, nil, assembly_idh)
      end
      def self.create_from_hash(task_action_type, hash, task_idh = nil)
        case task_action_type
          when 'CreateNode'  then CreateNode.new(:hash, hash, task_idh)
          when 'ConfigNode'  then ConfigNode.new(:hash, hash, task_idh)
          when 'PowerOnNode' then PowerOnNode.new(:hash, hash, task_idh)
          when 'InstallAgent' then InstallAgent.new(:hash, hash, task_idh)
          when 'ExecuteSmoketest' then ExecuteSmoketest.new(:hash, hash, task_idh)
          when 'Hash' then InstallAgent.new(:hash, hash, task_idh) #RICH-WF; Aldin compensating form bug in task creation
          when 'DeleteFromDatabase' then DeleteFromDatabase.new(:hash, hash, task_idh)
          else fail Error.new("Unexpected task_action_type (#{task_action_type})")
        end
      end
      def self.task_action_type
        @task_action_type ||= to_s.split('::').last
      end
      def task_action_type
        self.class.task_action_type()
      end

      def initialize(_type, hash, task_idh = nil)
        unless hash[:node].is_a?(Node)
          hash[:node] &&= Node.create_from_model_handle(hash[:node], task_idh.createMH(:node), subclass: true)
        end
        super(hash)
      end

      ###====== related to node(s); node can be a node group
      def node_is_node_group?
        self[:node].is_node_group?()
      end

      # opts can have keys
        # :cols - columns to return in teh node objects
      def nodes(opts = {})
        node_or_ng = self[:node]
        nodes = 
          if node_or_ng.is_node_group?()
            node_or_ng.get_node_group_members()
          else
            [node_or_ng]
          end
        if cols = opts[:cols]
          nodes.each { |node| node.update_object!(*cols) }
        end
        nodes
      end

      def node_id
        self[:node][:id]
      end

      def get_and_propagate_dynamic_attributes(result, opts = {})
        dyn_attr_val_info = get_dynamic_attributes_with_retry(result, opts)
        return if dyn_attr_val_info.empty?
        attr_mh = self[:node].model_handle_with_auth_info(:attribute)
        Attribute.update_and_propagate_dynamic_attributes(attr_mh, dyn_attr_val_info)
      end

      ###====== end: related to node(s); node can be a node group

      def attributes_to_set
        []
      end

      # virtual gets overwritten
      # updates object and the tasks in the model
      def get_and_update_attributes!(_task)
        # raise "You need to implement 'get_and_update_attributes!' method for class #{self.class}"
      end

      # virtual gets overwritten
      def add_internal_guards!(_guards)
        # raise "You need to implement 'add_internal_guards!' method for class #{self.class}"
      end

      def update_state_change_status_aux(task_mh, status, state_change_ids)
        rows = state_change_ids.map { |id| { id: id, status: status.to_s } }
        state_change_mh = task_mh.createMH(:state_change)
        Model.update_from_rows(state_change_mh, rows)
      end

      private

      def node_create_obj_optional_subclass(node)
        node && node.create_obj_optional_subclass()
      end

      def get_dynamic_attributes_with_retry(result, opts = {})
        ret = get_dynamic_attributes(result)
        if non_null_attrs = opts[:non_null_attributes]
          ret = retry_get_dynamic_attributes(ret, non_null_attrs) { get_dynamic_attributes(result) }
        end
        ret
      end

      def retry_get_dynamic_attributes(dyn_attr_val_info, non_null_attrs, count = 1, &block)
        if values_non_null?(dyn_attr_val_info, non_null_attrs)
          dyn_attr_val_info
        elsif count > RetryMaxCount
          fail Error.new("cannot get all attributes with keys (#{non_null_attrs.join(',')})")
        elsif block.nil?
          fail Error.new('Unexpected that block.nil?')
        else
          sleep(RetrySleep)
          retry_get_dynamic_attributes(block.call(), non_null_attrs, count + 1, &block)
        end
      end
      RetryMaxCount = 60
      RetrySleep = 1
      def values_non_null?(dyn_attr_val_info, keys)
        keys.each do |k|
          is_non_null = nil
          if match = dyn_attr_val_info.find { |a| a[:display_name] == k }
            if val = match[:attribute_value]
              is_non_null = (val.is_a?(Array) ? val.find { |el| el } : true)
            end
          end
          return nil unless is_non_null
        end
        true
      end

      # generic; can be overwritten
      def self.node_status(object, _opts)
        ret = PrettyPrintHash.new
        node = object[:node] || {}
        if name = node_status__name(node)
          ret.merge!(name: name)
        end
        if node.respond_to?(:is_node_group?) and node.is_node_group?
          ret.merge!(type: 'group')
        end
        if id = node[:id]
          ret.merge!(id: id)
        end
        ret
      end

      def self.node_status__name(node)
        node && Node.assembly_node_print_form?(node)
      end
    end

    class NodeLevel < OnNode
    end

    # TODO: Marked for removal [Haris] - Not sure but better check
    class PhysicalNode < self
      def initialize(_type, hash, task_idh = nil)
        unless hash[:node].is_a?(Node)
          hash[:node] &&= Node.create_from_model_handle(hash[:node], task_idh.createMH(:node), subclass: true)
        end
        super(hash)
      end

      def self.create_from_physical_nodes(target, node)
        node[:datacenter] = target
        hash = {
          node: node,
          datacenter: target,
          user_object: CurrentSession.new.get_user_object()
        }

        InstallAgent.new(:hash, hash)
      end

      def self.create_smoketest_from_physical_nodes(target, node)
        node[:datacenter] = target
        hash = {
          node: node,
          datacenter: target,
          user_object: CurrentSession.new.get_user_object()
        }

        ExecuteSmoketest.new(:hash, hash)
      end

      # virtual gets overwritten
      # updates object and the tasks in the model
      def get_and_update_attributes!(_task)
        # raise "You need to implement 'get_and_update_attributes!' method for class #{self.class}"
      end

      # virtual gets overwritten
      def add_internal_guards!(_guards)
        # raise "You need to implement 'add_internal_guards!' method for class #{self.class}"
      end
    end

    class DeleteFromDatabase < self
      def initialize(_type, hash, task_idh = nil)
        super(hash)
      end

      def self.create_hash(assembly, component, node, opts = {})
        hash = {
          assembly_idh: assembly.id_handle(),
          component: component,
          node: node,
          assembly: assembly,
          delete_action: opts[:delete_action],
          delete_params: opts[:delete_params]
        }
        new(:hash, hash)
      end

      def execute_delete_action(top_task_idh)
        case self[:delete_action]
         when 'delete_component'
          execute_delete_component(top_task_idh)
         else
          fail Error.new("Unsupported action type '#{self[:delete_action]}'!")
         end
      end

      def node_is_node_group?
        self[:node].is_node_group?()
      end

      def ret_command_and_control_adapter_info
        [:node_config, :server]
      end

      # virtual gets overwritten
      # updates object and the tasks in the model
      def get_and_update_attributes!(_task)
        # raise "You need to implement 'get_and_update_attributes!' method for class #{self.class}"
      end

      # virtual gets overwritten
      def add_internal_guards!(_guards)
        # raise "You need to implement 'add_internal_guards!' method for class #{self.class}"
      end

      def config_agent_type
        ConfigAgent::Type::Symbol.delete_from_database
      end

      def update_state_change_status(task_mh, status)
        # no op if no associated state change
        if self[:state_change_id]
          update_state_change_status_aux(task_mh, status, [self[:state_change_id]])
        end
      end

      private

      def execute_delete_component(top_task_idh)
        top_task = top_task_idh.create_object()
        if assembly = top_task.assembly
          assembly_instance = assembly.copy_as_assembly_instance
          delete_params = self[:delete_params]
          cmp_id = delete_params[:cmp_idh][:guid]
          cmp_idh = top_task.id_handle(model_name: :component, id: cmp_id)
          node_id = delete_params[:node_id]
          assembly_instance.delete_component(cmp_idh, node_id)
        else
          fail Error.new("Unexpected that top task does not have assembly!")
        end
      end
    end

    r8_nested_require('action', 'create_node')
    r8_nested_require('action', 'config_node')
    r8_nested_require('action', 'on_component')
    r8_nested_require('action', 'install_agent')
    r8_nested_require('action', 'execute_smoketest')

    class Result < HashObject
      def initialize(hash = {})
        super(hash)
        self[:result_type] = Aux.demodulize(self.class.to_s).downcase
      end

      class Succeeded < self
        def initialize(hash = {})
          super(hash)
        end
      end
      class Failed < self
        def initialize(error)
          super()
          self[:error] =  error.to_hash
        end
      end
      class Cancelled < self
        def initialize(hash = {})
          super(hash)
        end
      end
    end
  end
end; end
