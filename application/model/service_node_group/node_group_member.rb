module DTK
  class ServiceNodeGroup
    class NodeGroupMember < ::DTK::Node
      def self.model_name()
        :node
      end

      def clone_post_copy_hook(clone_copy_output,opts={})
        component = clone_copy_output.objects.first
      end
    end
  end
end
