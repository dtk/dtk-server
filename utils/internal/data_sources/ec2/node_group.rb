module XYZ
  module DSNormalizer
    class Ec2
      class NodeGroup < Top 
        definitions do
          target[:display_name] = source[:display_name]
          target[:description] = fn(:description,source[:security_groups])
        end
        class << self
          def relative_distinguished_name(source)
            source[:ref]
          end

          def description(security_groups)
            "Group corresponding to ec2 security groups [#{security_groups.join(",")}]"
          end
        end
      end
    end
  end
end

