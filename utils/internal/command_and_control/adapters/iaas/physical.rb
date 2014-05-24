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

      def check_security_group_and_key_pair(iaas_credentials)
        {}
      end
    end
  end
end
