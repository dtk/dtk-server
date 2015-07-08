module XYZ
  module DSNormalizer
    class Ec2
      class NodeGroupMember < Top
        definitions do
          target[:node_id] = foreign_key :node, source[:node_ref]
          target[:node_group_id] = foreign_key :node_group, source[:node_group_ref]
        end
        class << self
          def relative_distinguished_name(source)
            source[:ref]
          end
        end
      end
    end
  end
end
