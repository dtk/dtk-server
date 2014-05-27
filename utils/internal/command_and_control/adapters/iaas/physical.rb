module DTK
  module CommandAndControlAdapter
    class Physical < CommandAndControlIAAS
      def pbuilderid(node)
        node.get_field?(:ref)
      end

      def find_matching_node_binding_rule(node_binding_rules,target)
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

     private
      def raise_not_applicable_error(command)
        raise ErrorUsage.new("#{command.to_s.capitalize} is not applicable operation for physical nodes")
      end
    end
  end
end
