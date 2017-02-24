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
module DTK; class StateChange
  class Assembly < self
    def self.component_state_changes(assembly, component_type = nil)
      filter = [:and, [:eq, :assembly_id, assembly[:id]]]
      if (component_type == :smoketest)
        filter << [:eq, :basic_type, 'smoketest']
      else
        filter << [:neq, :basic_type, 'smoketest']
      end
      sp_hash = {
        cols: DTK::Component.pending_changes_cols,
        filter: filter
      }
      state_change_mh = assembly.model_handle(:state_change)

      changes = get_objs(assembly.model_handle(:component), sp_hash).map do |cmp|
        node = cmp.delete(:node)
        hash = {
          type: 'converge_component',
          component: cmp,
          node: node
        }
        create_stub(state_change_mh, hash)
      end
      ##group by node id
      ndx_ret = {}
      changes.each do |sc|
        node_id = sc[:node][:id]
        (ndx_ret[node_id] ||= []) << sc
      end

      # Sorting components on each node by 'ordered_component_ids' field
      sorted_ndx_ret = []
      begin
        ndx_ret.values.each do |component_list|
          ordered_component_ids = component_list.first[:node].get_ordered_component_ids()
          sorted_component_list = []
          component_list.each do |change|
            sorted_component_list[ordered_component_ids.index(change[:component][:id])] = change
          end
          sorted_ndx_ret << sorted_component_list.compact
        end
      rescue Exception => e
        # Sorting components failed. Returning random component order
        return ndx_ret.values
      end
      sorted_ndx_ret
    end

    ##
    # The method node_state_changes returns state changes related to nodes
    def self.node_state_changes(task_action_type, assembly, target_idh, opts = {})
      case task_action_type
       when :create_node
        node_state_changes__create_nodes(assembly, target_idh, opts)
       when :wait_for_node
        node_state_changes__wait_for_nodes(assembly, opts)
       else
        fail Error.new("Unexpcted task_action_type '#{task_action_type}'")
      end
    end

    private

    def self.node_state_changes__create_nodes(assembly, target_idh, opts = {})
      ret = []
      assembly_nodes = opts[:nodes] || assembly.get_nodes()
      return ret if assembly_nodes.empty?

      added_state_change_filters = [[:oneof, :node_id, assembly_nodes.map { |r| r[:id] }]]
      target_mh = target_idh.createMH()
      last_level = pending_create_node(target_mh, [target_idh], added_filters: added_state_change_filters)
      state_change_mh = target_mh.create_childMH(:state_change)
      until last_level.empty?
        ret += last_level
        last_level = pending_create_node(state_change_mh, last_level.map(&:id_handle))
      end
      ret
      if opts[:just_leaf_nodes]
        ret.reject { |sc| sc[:node].is_node_group?() }
      end
    end

    def self.node_state_changes__wait_for_nodes(assembly, opts = {})
      ret = []
      unless opts[:just_leaf_nodes]
        fail Error.new('Only supporting option :just_leaf_nodes')
      end
      # TODO: should we have in call below the option: remove_assembly_wide_node: true
      nodes = opts[:nodes] || assembly.get_leaf_nodes(cols: [:id, :display_name, :type, :external_ref, :admin_op_status])

      nodes_to_start = nodes.select do |n| 
        op_status = n.get_and_update_operational_status!
        case op_status
        when 'stopped', 'stopping' then true
        when 'running' then false
        else
          Log.info("nodes_to_start calculation when op status is '#{op_status}'")
          true
        end
      end
      # TODO: DTK-2915: took out below for above which was comment here for a while
      #nodes_to_start = nodes

      return ret if nodes_to_start.empty?

      state_change_mh = assembly.model_handle(:state_change)
      nodes_to_start.map do |node|
        hash = {
          type: 'power_on_node',
          node: node
        }
        create_stub(state_change_mh, hash)
      end
    end
  end
end; end
