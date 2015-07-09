module DTK
  module CommandAndControlAdapter
    class Physical < CommandAndControlIAAS
      def pbuilderid(node)
        node.update_object!(:ref, :external_ref)
        if node[:ref] =~ Regexp.new("^#{Node::TargetRef.physical_node_prefix()}")
          node[:ref]
        else
          if ret = Node::TargetRef::Input::InventoryData.pbuilderid?(node[:external_ref])
            ret
          else
            fail Error.new("Cannot compute the communication id for physical node with id (#{node.id})")
          end
        end
      end

      def find_matching_node_binding_rule(_node_binding_rules, _target)
        nil
      end

      def references_image?(_node_external_ref)
        nil
      end

      def destroy_node?(_node, _opts = {})
        true #vacuously succeeds
      end

      def check_iaas_properties(_iaas_properties, _opts = {})
        {}
      end

      def start_instances(_nodes)
        raise_not_applicable_error(:start)
      end

      def stop_instances(_nodes)
        raise_not_applicable_error(:stop)
      end

      def execute(_task_idh, _top_task_idh, task_action)
        # Aldin: just for testing
        node = task_action[:node]
        external_ref = node[:external_ref] || {}

        { status: 'succeeded',
          node: {
            external_ref: external_ref
          }
        }
      end

      private

      def raise_not_applicable_error(command)
        fail ErrorUsage.new("#{command.to_s.capitalize} is not applicable operation for physical nodes")
      end
    end
  end
end
