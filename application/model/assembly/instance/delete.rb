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
module DTK; class  Assembly
  class Instance
    module DeleteClassMixin
      # opts can have keys:
      #   :destroy_nodes
      #   :uninstall
      def delete(assembly_idhs, opts = {})
        if assembly_idhs.is_a?(Array)
          return if assembly_idhs.empty?
        else
          assembly_idhs = [assembly_idhs]
        end
        # first check if target with service instances, then Delete.contents
        target_idhs_to_delete = Delete.target_idhs_to_delete?(assembly_idhs)
        Delete.contents(assembly_idhs, destroy_nodes: opts[:destroy_nodes])

        if opts[:uninstall]
          delete_instances(assembly_idhs)
          delete_instances(target_idhs_to_delete) unless target_idhs_to_delete.empty?
        end
      end

      def delete_contents(assembly_idhs, opts = {})
        Delete.contents(assembly_idhs, opts)
      end
    end

    module DeleteMixin
      def destroy_and_reset_nodes
        nodes = Delete.get_nodes_simple(model_handle(:node), [id()])
        # TODO: DTK-1857
        if nodes.find(&:is_node_group?)
          fail ErrorUsage.new('destroy_and_reset_nodes not supported for service instances with node groups')
        end
        target_idh = get_target.id_handle()
        nodes.map { |node| node.destroy_and_reset(target_idh) }
      end

      def delete_node(node_idh, opts = {})
        unless node_idh.is_a?(IDHandle)
          node_idh = id_handle().createIDH(model_name: :node, id: node_idh[:guid])
        end

        node =  node_idh.create_object()
        # TODO: check if cleaning up dangling links when assembly node deleted
        if node.is_node_group?
          node.update_object!(:display_name)
          fail ErrorUsage.new("Node with name '#{node[:display_name]}' does not exist. If you want to delete node group you can use 'delete-node-group node-group-name'")
        end

        if node_group = is_node_group_member?(node_idh)
          # if node-group member and last one then delete node group as well
          node_group = node_group.create_obj_optional_subclass()
          Delete.node(node, opts.merge(update_task_template: true, assembly: self))
          node_group.delete_object(update_task_template: true, assembly: self) if node_group.get_node_group_members.size == 0
        else
          delete_node_opts = { assembly: self }
          delete_node_opts.merge!(update_task_template: true) unless opts[:do_not_update_task_template]
          Delete.node(node, opts.merge(delete_node_opts))
        end
      end

      def delete_node_group(node_group_idh, opts = {})
        unless node_group_idh.is_a?(IDHandle)
          node_group_idh = id_handle().createIDH(model_name: :node, id: node_group_idh[:guid])
        end

        node_group = node_group_idh.create_object()

        unless node_group.is_node_group?
          node_group.update_object!(:display_name)
          fail ErrorUsage.new("Node group with name '#{node_group[:display_name]}' does not exist")
        end

        node_group = node_group.create_obj_optional_subclass()
        node_group.delete_group_members(0)
        node_group.delete_object(update_task_template: !opts[:do_not_update_task_template], assembly: self)
      end

      def delete_component(component_idh, node_id = nil, opts = {})
        unless component_idh.is_a?(IDHandle)
          component_idh = id_handle().createIDH(model_name: :component, id: component_idh[:guid])
        end

        component_filter = [:and, [:eq, :id, component_idh.get_id()], [:eq, :assembly_id, id()]]
        node = nil
        node_component_node = nil
        # first check that node belongs to this assebmly
        if node_id.is_a?(Fixnum)
          sp_hash = {
            cols: [:id, :display_name, :group_id],
            filter: [:and, [:eq, :id, node_id], [:eq, :assembly_id, id()]]
          }

          unless node = Model.get_obj(model_handle(:node), sp_hash)
            fail ErrorIdInvalid.new(node_id, :node)
          end
          component_filter << [:eq, :node_node_id, node_id]
        end

        # also check that component_idh belongs to this instance and to this node
        sp_hash = {
          #:only_one_per_node,:ref are put in for info needed when getting title
          cols: [:id, :display_name, :node_node_id, :only_one_per_node, :ref, :component_type, :assembly_id],
          filter: component_filter
        }
        component = Component::Instance.get_obj(model_handle(:component), sp_hash)
        unless component
          fail ErrorIdInvalid.new(component_idh.get_id(), :component)
        end

        # if node as component take node so it can be deleted at the end
        if component.is_node_component?
          node_component = NodeComponent.node_component(component)
          node_component_node = node_component.node
        end

        # this will delete node as component node
        if node_component_node
          if opts[:delete_node_as_component_node] || node_component_node.get_components.empty?
            unless node_component_node.is_assembly_wide_node?
              if node_component_node.is_node_group?
                delete_node_group(node_component_node.id_handle, opts)
              else
                delete_node(node_component_node.id_handle, opts)
              end
            end
          end
        end

        node ||= component_idh.createIDH(model_name: :node, id: component[:node_node_id]).create_object()
        ret = nil
        Transaction do
          node.update_dangling_links(component_idhs: [component.id_handle()])
          Task::Template::ConfigComponents.update_when_deleted_component?(self, node, component, opts) unless opts[:do_not_update_task_template]

          ret = Model.delete_instance(component_idh)

          # recompute the locked module refs
          ModuleRefs::Lock.create_or_update(self)
        end

        if opts[:delete_node_if_last_cmp]
          if node && node.get_components.empty?
            delete_node(node.id_handle, opts) unless node.is_assembly_wide_node?
          end
        end

        ret
      end
    end

    class Delete < self
      # opts can have keys:
      #   :do_not_raise
      #   :destroy_nodes
      def self.contents(assembly_idhs, opts = {})
        return if assembly_idhs.empty?

        delete(get_sub_assemblies(assembly_idhs).map(&:id_handle))

        assembly_ids     = assembly_idhs.map(&:get_id)
        idh              = assembly_idhs.first
        Delete.assembly_modules?(assembly_idhs, do_not_raise: opts[:do_not_raise])
        Delete.assembly_nodes(idh.createMH(:node), assembly_ids, destroy_nodes: opts[:destroy_nodes])
        Delete.task_templates(idh.createMH(:task_template), assembly_ids)
      end

      def self.get_nodes_simple(node_mh, assembly_ids)
        assembly_idhs = assembly_ids.map { |id| node_mh.createIDH(id: id, model_name: :assembly_instance) }
        Assembly::Instance.get_nodes_simple(assembly_idhs, ret_subclasses: true)
      end

      private

      def self.task_templates(task_template_mh, assembly_ids)
        sp_hash = {
          cols: [:id, :display_name],
          filter: [:oneof, :component_component_id, assembly_ids]
        }
        delete_instances(get_objs(task_template_mh, sp_hash).map(&:id_handle))
      end

      # opts can have keys:
      #   :do_not_raise
      def self.assembly_modules?(assembly_idhs, opts = {})
        assembly_idhs.each do |assembly_idh|
          assembly = create_from_id_handle(assembly_idh)
          AssemblyModule.delete_modules?(assembly, opts)
        end
      end

      # This only deletes the nodes that the assembly 'owns'; with sub-assemblies, the assembly base will own the node
      def self.assembly_nodes(node_mh, assembly_ids, opts = {})
        Delete.nodes(node_mh, assembly_ids, opts)
      end

      # opts can have keys:
      #   :destroy_nodes
      def self.nodes(node_mh, assembly_ids, opts = {})
        nodes = get_nodes_simple(node_mh, assembly_ids)
        nodes.map { |node| Delete.node(node, opts) }
      end

      # TODO: double check if Transaction needed; if so look at whether for same reason put in destoy and reset
      def self.node(node, opts = {})
        ret = nil
        Transaction do
          ret =
            if opts[:destroy_nodes]
              node.destroy_and_delete(opts)
            else
              node.delete_object(opts)
            end
        end
        ret
      end

      # Returns the target_ids to delete
      def self.target_idhs_to_delete?(assembly_idhs)
        ndx_targets_to_delete = {}
        assembly_idhs.each do |assembly_idh|
          assembly    = assembly_idh.create_object
          assembly_id = assembly.id
          if target = Service::Target.target_when_target_assembly_instance?(assembly)
            dep_assemblies = Assembly::Instance.get(target.model_handle(:assembly_instance), target_idh: target.id_handle)
            dep_assemblies.reject!{ |a| a.id == assembly_id }

            # pull out workspace assembly if it is in dep_assemblies
            workspace = nil
            dep_assemblies.reject! { |a| workspace = Workspace.workspace?(a) }

            unless dep_assemblies.empty?
              dep_assembly_names = dep_assemblies.map{ |a| a.get_field?(:display_name) }.join(', ')
              fail ErrorUsage.new("The target service '#{assembly.get_field?(:display_name)}' cannot be deleted because the service instance(s) (#{dep_assembly_names}) are dependent on it")
            end
            if deleted_target_is_default?(target)
              # make builtin target the default
              if builtin_target = Target::Instance.get_builtin_target(target.model_handle)
                Target::Instance.set_default_target(builtin_target)
              end
              # purge workspace and reset its target if workspace is non null meaning it is dependent on target
              purge_workspace(workspace, builtin_target, target) if workspace
            end
            ndx_targets_to_delete[target.id] ||= target
          end
        end
        ndx_targets_to_delete.values.map(&:id_handle)
      end

      def self.deleted_target_is_default?(target)
        current_default_target = Target::Instance.get_default_target(target.model_handle)
        current_default_target && current_default_target.id == target.id
      end        
    
      def self.purge_workspace(workspace, new_default_target, target)
        if current_workspace_target = workspace.get_target()
          if current_workspace_target.id == target.id
            workspace.set_target(new_default_target, mode: :from_delete_target) if new_default_target
            workspace.purge(destroy_nodes: true)
          end
        end
      end
    end
  end
end; end
