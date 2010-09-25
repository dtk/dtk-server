module XYZ
  module DSNormalizer
    class Ec2
      class NetworkPartitionSecurityGroup < Top 
        definitions do
          target[:display_name] = source[:name]
          target[:description] = source[:description]
        end
        class << self
          def unique_keys(source)
            [source[:name]]
          end

          def relative_distinguished_name(source)
            source[:name]
          end
        end
      end
    end
  end
end

