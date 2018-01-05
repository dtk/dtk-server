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
module DTK
  class Target
    class Clone
      require_relative('clone/objects')
      require_relative('clone/special_node_attributes')

      module Mixin
        def clone_post_copy_hook(clone_copy_output, opts = {})
          Clone.clone(self, clone_copy_output, opts)
        end
      end

      def initialize(target, clone_copy_output)
        @target            = target
        @objects           = Objects.new(clone_copy_output)
        @assembly_instance = clone_copy_output.assembly?(subclass_object: true)
      end
      private :initialize

      # opts can have keys:
      #   :version
      def self.clone(target, clone_copy_output, opts = {})
        new(target, clone_copy_output).clone(opts)
      end

      def clone(opts = {})
        #adjust link_def_id on ports
        set_ports_link_def_and_cmp_ids

        return if self.nodes.empty?
        SpecialNodeAttributes.process(self.nodes, self.assembly_instance)

        # The method create_target_refs_and_links?
        # - creates if needed target refs and links to them
        # - moves node attributes to the target refs
        # - returns any needed 'create node' state change objects, which designate that
        #   target ref node needs to be created as opposed to it exists already
        create_target_refs_and_links?

        # Computing port_links (and also attribute links after create_target_refs_and_links
        # because relying on the node attributes to be shifted to target refs if connected to target refs
        create_attribute_links__clone_if_needed

        # TODO: currently this is not being used
        # if settings = opts[:service_settings]
        #   settings.apply_settings(target, assembly)
        # end

        update_task_templates

        create_service_instance_module_refs(version: opts[:version])

        unless self.components_hash_form.empty?
          component_new_items = self.components_hash_form.map do |child_hash|
            { new_item: child_hash[:id_handle], parent: self.target_idh }
          end
          StateChange.create_pending_change_items(component_new_items)
        end
      end

      protected

      attr_reader :target, :objects, :assembly_instance

      def nodes
        @nodes ||= self.objects.nodes
      end

      def ports
        @ports ||= self.objects.ports
      end
      def port_links
        @port_links ||= self.objects.port_links
      end

      def link_defs
        @link_defs ||= self.objects.link_defs
      end

      def components_hash_form
        @components_hash_form ||= self.objects.components(hash_form: true)
      end

      def components
        @components ||= self.objects.components
      end

      def task_templates
        @task_templates ||= self.objects.task_templates
      end

      def module_branch
        @module_branch ||= ret_module_branch
      end

      def target_idh 
        @target_idh ||= self.target.id_handle
      end

      private

      def set_ports_link_def_and_cmp_ids
        return if self.ports.empty?
        port_mh = self.ports.first.id_handle.createMH
        Port.set_ports_link_def_and_cmp_ids(port_mh, self.ports, self.components, self.link_defs)
      end

      def create_target_refs_and_links?
        nodes_for_create_sc = Node::TargetRef::Clone.new(self.target, self.assembly_instance, self.nodes).create_target_refs_and_links?
        create_state_changes_for_create_node?(nodes_for_create_sc)
      end

      # find the port_links under the assembly and then add attribute_links associated with it
      def create_attribute_links__clone_if_needed
        return if self.port_links.empty?
        sp_hash = {
          cols: [:id, :display_name, :group_id, :input_id, :output_id],
          filter: [:oneof, :id, self.port_links.map(&:id)]
        }
        port_link_mh = self.port_links.first.id_handle.createMH
        Model.get_objs(port_link_mh, sp_hash).each do |port_link|
          port_link.create_attribute_links__clone_if_needed(self.target.id_handle, set_port_link_temporal_order: true)
        end
      end

      def update_task_templates
        add_node_component_tasks_if_needed      
        add_service_module_task_templates
      end

      def add_node_component_tasks_if_needed
        assembly_wide_node = nil
        real_nodes         = []
        self.nodes.each do |node|
          if node.is_assembly_wide_node?
            assembly_wide_node = node
          else
            real_nodes << node
          end
        end
        return if real_nodes.empty? or assembly_wide_node.nil?
        NodeComponent.node_components(real_nodes, self.assembly_instance).map do |node_component|
          component = node_component.component
          node_name = node_component.node.display_name
          task_template_opts = { component_title: node_name, insert_strategy: :insert_at_start }
          Task::Template::ConfigComponents.update_when_added_component_or_action?(self.assembly_instance, assembly_wide_node, component, task_template_opts)
        end
      end
      
      def add_service_module_task_templates
        task_templates = self.module_branch.get_service_module_task_templates
        return if task_templates.empty?

        # remove any service_level task_templates that match an assembly level one using :task_action as the key
        assembly_task_actions = self.task_templates.map { |t| t[:task_action] }
        self.task_templates.reject! { |t| assembly_task_actions.include?(t) }
        return if self.task_templates.empty?

        Task::Template.clone_to_assembly(self.assembly_instance, self.task_templates)
      end


      # opts can have keys
      #   :version
      def create_service_instance_module_refs(opts = {})
        Log.error("TODO: DTK-3366: is analog to 'ModuleRefs::Lock.create_or_update(assembly, raise_errors: true, version: opts[:version])' neede?")
        # LockedModuleRefs::ServiceInstance.create(self.assembly_instance)
      end
      
      def create_state_changes_for_create_node?(nodes_for_create_sc)
        #Do not create stages for node that are physical
        pruned_nodes = nodes_for_create_sc.reject do |node|
          (node.get_field?(:external_ref) || {})[:type] == 'physical'
        end
        return if pruned_nodes.empty?

        node_new_items = pruned_nodes.map { |node| { new_item: node.id_handle, parent: self.target_idh } }
        sc_hashes = create_state_change_objects(node_new_items)
        create_state_changes_for_node_group_members(pruned_nodes, sc_hashes)
        nil
      end

      def create_state_changes_for_node_group_members(pruned_nodes, sc_hashes)
        ret = []
        node_groups = pruned_nodes.select(&:is_node_group?)
        return ret if node_groups.empty?
        ng_mh =  node_groups.first.model_handle
        ndx_sc_ids = sc_hashes.inject({}) { |h, sc| h.merge(sc[:node_id] => sc[:id]) }
        sc_mh = self.target_idh.createMH(:state_change)
        new_items_hash = []
        NodeGroup.get_ndx_node_group_members(node_groups.map(&:id_handle)).each do |ng_id, node_members|
          unless ng_state_change_id = ndx_sc_ids[ng_id]
            Log.eror('Unexpected that ndx_sc_ihs[ng_id] is null')
            next
          end
          ng_state_change_idh = sc_mh.createIDH(id: ng_state_change_id)
          node_members.each do |node|
            new_items_hash << { new_item: node.id_handle, parent: ng_state_change_idh }
          end
        end
        create_state_change_objects(new_items_hash)
      end

      def create_state_change_objects(new_items_hash)
        opts_sc = { target_idh: self.target_idh, returning_sql_cols: [:id, :display_name, :group_id, :node_id] }
        StateChange.create_pending_change_items(new_items_hash, opts_sc)
      end

      def ret_module_branch
        module_branch_id = self.assembly_instance.get_field?(:module_branch_id)
        self.assembly_instance.model_handle(:module_branch).createIDH(id: module_branch_id).create_object
      end

    end
  end
end
