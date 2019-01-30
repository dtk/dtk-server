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
  class Template
    class ConfigComponents < self
      require_relative('config_components/persistence')

      DefaultTaskActionForUpdates = nil

      # opts can have keys:
      #   :component_title
      #   :skip_if_not_found
      #   :insert_strategy
      #   :add_delete_action
      #   :action_def
      #   :splice_in_delete_action
      # It is action if :action_def given
      def self.update_when_added_component_or_action?(assembly, node, component, opts = {})
        # only updating the create action task template and only if it is persisted
        assembly_cmp_actions = ActionList::ConfigComponents.get(assembly)
        if task_template_content = get_template_content_aux?([:assembly], assembly, assembly_cmp_actions, DefaultTaskActionForUpdates, opts)
          new_action = Action.create(component.merge(node: node, title: opts[:component_title]), opts)
          gen_constraints_proc = proc { TemporalConstraints::ConfigComponents.get(assembly, assembly_cmp_actions) }
          insert_opts = { 
            gen_constraints_proc: gen_constraints_proc,
            add_delete_action: opts[:add_delete_action],
            insert_strategy: opts[:insert_strategy]
          }
          if updated_template_content = task_template_content.insert_action?(new_action, assembly_cmp_actions, insert_opts)
            Persistence::AssemblyActions.persist(assembly, updated_template_content)
          end
        end
      end

      def self.update_when_deleted_component?(assembly, node, component, opts = {})
        # TODO: currently only updating the create action task template and only if it is persisted
        # makes sense to also automtically delete component in other workflow actions aside from once in spliced in delete subtask
        action_to_delete = Action.create(component.add_title_field?.merge(node: node))
        delete_action?(assembly, action_to_delete, DefaultTaskActionForUpdates, opts)

        # DTK-3144 - when deleting component we need to delete all it's actions from workflow
        (component.get_action_defs || []).each do |a_def|
          action_to_delete = Action.create(component.add_title_field?.merge(node: node), action_def: a_def)
          delete_action?(assembly, action_to_delete, DefaultTaskActionForUpdates, opts)
        end
      end

      def self.cleanup_after_node_has_been_deleted?(assembly, node)
        # TODO: currently only updating the create action task template and only if it is persisted
        # makes sense to also automtically delete node components in other workflow actions aside from once in spliced in delete subtask
        delete_actions_on_node?(assembly, node, DefaultTaskActionForUpdates)
      end

      # opts can have
      #  :assembly
      #  :workflow_action
      #  :service_module_workflow - Boolean
      #  :hash_in_key_form - Boolean
      def self.find_parse_error?(workflow_hash, opts = {})
        ret = nil
        workflow_action = opts[:workflow_action]
        unless workflow_hash.kind_of?(Hash)
          if workflow_action
            return ParsingError.new("Workflow for action '?1' is ill-formed because it is not a hash: ?2", workflow_action, workflow_hash)
          else
            return ParsingError.new('Workflow is ill-formed because it is not a hash: ?1', workflow_hash)
          end
        end
        
        workflow_hash = Aux.convert_keys_to_symbols_recursive(workflow_hash) unless opts[:keys_are_in_symbol_form]
        
        if opts[:service_module_workflow]
          unless workflow_action ||= workflow_hash[:name]
            return ParsingError.new("Unexpected that a service module workflow does not have a 'name' parameter.")
          end
          if workflow_hash.key?(:assembly_action)
            return ParsingError.new("Service module workflow cannot have 'assembly_action' key.") 
          end
          if workflow_action == 'create'
            return ParsingError.new("Service module workflow cannot have a 'create' action.")
          end
        end
        
        begin
          cmp_actions = (opts[:assembly] && ActionList::ConfigComponents.get(opts[:assembly]))
          serialized_content = serialized_content_hash_form(workflow_hash)
          Content.parse_and_reify(serialized_content, cmp_actions, just_parse: true)
        rescue ParsingError => parse_error
          return parse_error
        end
        ret
      end
      
      def self.get_serialized_template_content(assembly, task_action = nil)
        Persistence::AssemblyActions.get_serialized_content_from_assembly(assembly, task_action)
      end
      
      # action_types is scalar or array with elements
      # :assembly
      # :node_centric
      def self.get_or_generate_template_content(action_types, assembly, opts = {})
        action_types = Array(action_types)
        raise_error_if_unsupported_action_types(action_types)

        task_action = opts[:task_action]
        opts_action_list = Aux.hash_subset(opts, [:component_type_filter, :nodes_to_create, :full_workflow])

        cmp_actions = ActionList::ConfigComponents.get(assembly, opts_action_list)

        # first see if there is a persistent serialized task template for assembly instance and that it should be used
        opts_get_template = Aux.hash_subset(opts, [:task_params, :serialized_form, :attempts, :retry, :nodes])
        if template_content = get_template_content_aux?(action_types, assembly, cmp_actions, task_action, opts_get_template)
          return template_content
        end

        node_as_components = []
        cmp_actions.each{ |relevant_action| (node_as_components << NodeComponent.node_component?(relevant_action)) if NodeComponent.is_node_component?(relevant_action) }
        nodes_as_cmps_create_subtask = create_nodes_as_components_subtask(assembly, cmp_actions, node_as_components)

        # otherwise do the temporal processing to generate template_content
        cmp_actions.delete_if { |relevant_action| NodeComponent.is_node_component?(relevant_action) }
        opts_generate = (node_centric_first_stage?() ? { node_centric_first_stage: true } : {})
        template_content = generate_from_temporal_contraints([:assembly, :node_centric], assembly, cmp_actions, opts_generate)
        template_content.splice_in_at_beginning!([nodes_as_cmps_create_subtask], opts_generate) unless nodes_as_cmps_create_subtask.empty?

        unless opts[:serialized_form]
          # persist assembly action part of what is generated
          Persistence::AssemblyActions.persist(assembly, template_content, task_action, { subtask_order: opts[:subtask_order] })
        end

        template_content
      end

      private

      # using this to create nodes as components creation concurrent subtask
      def self.create_nodes_as_components_subtask(assembly, assembly_cmp_actions, node_as_components)
        empty_actions = ActionList::ConfigComponents.new
        nodes_as_cmps_subtask = generate_from_temporal_contraints([:assembly, :node_centric], assembly, empty_actions, {subtask_order: 'concurrent', custom_name: 'create nodes'})
        updated = false

        assembly_wide_node = assembly.has_assembly_wide_node?
        node_as_components.delete_if { |nc| nc.nil? }

        node_as_components.each do |node_component|
          component = node_component.component
          node_name = node_component.node.display_name
          task_template_opts = { component_title: node_name, insert_strategy: :insert_at_start }

          new_action = Action.create(component.merge(node: assembly_wide_node, title: task_template_opts[:component_title]), task_template_opts)
          gen_constraints_proc = proc { TemporalConstraints::ConfigComponents.get(assembly, assembly_cmp_actions) }
          insert_opts = {
            gen_constraints_proc: gen_constraints_proc,
            add_delete_action: task_template_opts[:add_delete_action],
            insert_strategy: task_template_opts[:insert_strategy]
          }
          nodes_as_cmps_subtask.insert_action?(new_action, assembly_cmp_actions, insert_opts)
        end

        nodes_as_cmps_subtask
      end

      def self.raise_error_if_unsupported_action_types(action_types)
        unless action_types.include?(:assembly)
          fail Error.new('Not supported when action types does not contain :assembly')
        end
        illegal_action_types = (action_types - [:assembly, :node_centric])
        unless illegal_action_types.empty?
          fail Error.new("Illegal action type(s) (#{illegal_action_types.join(',')})")
        end
      end
      def self.node_centric_first_stage?
        true
      end

      def self.get_template_content_aux?(action_types, assembly, cmp_actions, task_action, opts = {})
        if assembly_action_content = Persistence::AssemblyActions.get_content_for(assembly, cmp_actions, task_action, opts)
          if action_types == [:assembly]
            assembly_action_content
          else #action_types has both and assembly and node_centric
            add_node_centric_steps(assembly_action_content, assembly, cmp_actions)
          end
        end
      end

      def self.add_node_centric_steps(assembly_action_content, assembly, cmp_actions)
        node_centric_content = generate_from_temporal_contraints(:node_centric, assembly, cmp_actions)
        if node_centric_content.empty?
          assembly_action_content
        else
          opts_splice = (node_centric_first_stage?() ? { node_centric_first_stage: true } : {})
          assembly_action_content.splice_in_at_beginning!(node_centric_content, opts_splice)
        end
      end

      def self.generate_from_temporal_contraints(action_types, assembly, cmp_actions, opts = {})
        action_types =  Array(action_types)
        relevant_actions =
          if action_types == [:assembly]
            cmp_actions.select { |a| a.source_type() == :assembly }
          elsif action_types == [:node_centric]
            cmp_actions.select { |a| a.source_type() == :node_group }
          else #action_types consists of :assembly and :node_centric
            cmp_actions
          end

        # remove no op actions
        relevant_actions.reject! { |a| a.is_no_op? }

        temporal_constraints = TemporalConstraints::ConfigComponents.get(assembly, relevant_actions)
        Content.new(temporal_constraints, relevant_actions, opts)
      end

      def self.delete_action?(assembly, action_to_delete, task_action, opts = {})
        assembly_cmp_actions = ActionList::ConfigComponents.get(assembly)
        if task_template_content = get_template_content_aux?([:assembly], assembly, assembly_cmp_actions, task_action)
          if updated_template_content = task_template_content.delete_explicit_action?(action_to_delete, assembly_cmp_actions, opts)
            Persistence::AssemblyActions.persist(assembly, updated_template_content)
          end
        end
      end

      def self.delete_actions_on_node?(assembly, node, task_action)
        assembly_cmp_actions = ActionList::ConfigComponents.get(assembly)
        if task_template_content = get_template_content_aux?([:assembly], assembly, assembly_cmp_actions, task_action)
          if updated_template_content = task_template_content.delete_actions_on_node?(node, assembly_cmp_actions)
            Persistence::AssemblyActions.persist(assembly, updated_template_content)
          end
        end
      end
      
    end
  end
end; end
