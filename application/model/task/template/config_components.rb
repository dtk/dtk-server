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
      r8_nested_require('config_components', 'persistence')

      def self.update_when_added_component?(assembly, node, new_component, component_title, opts = {})
        # only updating the create action task template and only if it is persisted
        assembly_cmp_actions = ActionList::ConfigComponents.get(assembly)
        task_action = DefaultTaskActionForUpdates
        if task_template_content = get_template_content_aux?([:assembly], assembly, assembly_cmp_actions, task_action, opts)
          new_action = Action.create(new_component.merge(node: node, title: component_title), opts)
          gen_constraints_proc = proc { TemporalConstraints::ConfigComponents.get(assembly, assembly_cmp_actions) }
          if updated_template_content = task_template_content.insert_action?(new_action, assembly_cmp_actions, gen_constraints_proc)
            Persistence::AssemblyActions.persist(assembly, updated_template_content)
          end
        end
      end

      def self.update_when_deleted_component?(assembly, node, component)
        # TODO: currently only updating the create action task template and only if it is persisted
        # makes sense to also automtically delete component in other actions
        assembly_cmp_actions = ActionList::ConfigComponents.get(assembly)
        task_action = DefaultTaskActionForUpdates
        if task_template_content = get_template_content_aux?([:assembly], assembly, assembly_cmp_actions, task_action)
          action_to_delete = Action.create(component.add_title_field?().merge(node: node))
          if updated_template_content = task_template_content.delete_explicit_action?(action_to_delete, assembly_cmp_actions)
            Persistence::AssemblyActions.persist(assembly, updated_template_content)
          end
        end
      end
      DefaultTaskActionForUpdates = nil
      
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

      # action_types is scalar or array with elements
      # :assembly
      # :node_centric
      def self.get_or_generate_template_content(action_types, assembly, opts = {})
        action_types = Array(action_types)
        raise_error_if_unsupported_action_types(action_types)

        task_action = opts[:task_action]
        opts_action_list = Aux.hash_subset(opts, [:component_type_filter])
        cmp_actions = ActionList::ConfigComponents.get(assembly, opts_action_list)

        # first see if there is a persistent serialized task template for assembly instance and that it should be used
        opts_get_template = Aux.hash_subset(opts, [:task_params, :serialized_form])
        if template_content = get_template_content_aux?(action_types, assembly, cmp_actions, task_action, opts_get_template)
          return template_content
        end

        # otherwise do the temporal processing to generate template_content
        opts_generate = (node_centric_first_stage?() ? { node_centric_first_stage: true } : {})
        template_content = generate_from_temporal_contraints([:assembly, :node_centric], assembly, cmp_actions, opts_generate)

        unless opts[:serialized_form]
          # persist assembly action part of what is generated
          Persistence::AssemblyActions.persist(assembly, template_content, task_action)
        end

        template_content
      end

      private

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

    end
  end
end; end
