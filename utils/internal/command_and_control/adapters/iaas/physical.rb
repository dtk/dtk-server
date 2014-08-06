module DTK
  module CommandAndControlAdapter
    class Physical < CommandAndControlIAAS
      def pbuilderid(node)
        node.get_field?(:ref)
      end

      def find_matching_node_binding_rule(node_binding_rules,target)
        nil
      end

      def references_image?(node_external_ref)
        nil
      end

      def destroy_node?(node,opts={})
        true #vacuously succeeds
      end

      def check_iaas_properties(iaas_properties)
        Hash.new
      end

      def start_instances(nodes)
        raise_not_applicable_error(:start)
      end

      def stop_instances(nodes)
        raise_not_applicable_error(:stop)
      end

      def execute(task_idh,top_task_idh,task_action)
        # Aldin: just for testing
        node = task_action[:node]
        external_ref = node[:external_ref]||{}

        {:status => "succeeded",
          :node => {
            :external_ref => external_ref
          }
        }
      end

     private
      def raise_not_applicable_error(command)
        raise ErrorUsage.new("#{command.to_s.capitalize} is not applicable operation for physical nodes")
      end
    end
  end
end
