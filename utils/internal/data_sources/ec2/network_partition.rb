module XYZ
  module DSNormalizer
    class Ec2
      class NetworkPartition < Top
        definitions do
          target[:display_name] = source[:name]
          target[:description] = source[:description]
        end
        class << self
          def relative_distinguished_name(source)
            source[:name]
          end
        end
      end
    end
  end
end

