module DTK; class Assembly::Instance
  module DeleteMixin
    module Components
      def self.delete(service_instance, params, opts = {})
        component_name    = params.last
        assembly_instance = service_instance.copy_as_assembly_instance
        augmented_cmps    = assembly_instance.get_augmented_components(Opts.new(filter_component: component_name))

        if params.size == 2
          node_name_param = params.find{ |param| param.include?('ec2::node') }
          if node_name_param
            node_name = node_name_param.match(/ec2::node\[(.*)\]/)[1]
            node = assembly_instance.get_node?([:eq, :display_name, node_name])
          end
        end

        if augmented_cmps.empty?
          raise ErrorUsage, "Component '#{component_name}' does not match any components"
        else
          node        ||= assembly_instance.has_assembly_wide_node?
          matching_cmps = augmented_cmps.select{|cmp| cmp[:node][:display_name] == node[:display_name]}

          if matching_cmps.size > 1
            raise ErrorUsage, "Unexpected that component name '#{component_name}' match multiple components"
          else
            component = ::DTK::Component::Instance.create_from_component(matching_cmps.first)

            # no op if to_be_deleted is set since this is peristent setting we use to detect whether the task update has been done already
            return if component.get_field?(:to_be_deleted)

            if opts[:force_delete] || !node_has_been_created?(node) || !component_delete_action_def?(component)
              assembly_instance.delete_component(component.id_handle, node.id, {delete_node_as_component_node: true})
            else
              task_params = { task_action: "#{component_name}.delete" }
              task_opts = Opts.new(delete_action: 'delete_component', delete_params: [component.id_handle, node.id])
              task_opts.merge!(delete_node_as_component_node: true)
              assembly_instance.exec__delete_component(task_params, task_opts)
            end
            
            nil
          end
        end

      end

      def self.component_delete_action_def?(component)
        ::DTK::Component::Instance.create_from_component(component).get_action_def?('delete')
      end

      def self.node_has_been_created?(node)
        node.get_admin_op_status != 'pending'
      end

      def self.remove_component_actions_from_task_template(assembly_instance, node, component)
        Task::Template::ConfigComponents.update_when_deleted_component?(assembly_instance, node, component) unless ::DTK::Component::Domain::Node::Canonical.is_type_of?(component)
      end
    end
  end
end; end