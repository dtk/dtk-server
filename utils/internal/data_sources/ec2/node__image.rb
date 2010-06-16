require File.expand_path("ec2", File.dirname(__FILE__))
module XYZ
  module DSNormalizer
    class Ec2
      class NodeImage < Top 
       private
        definitions do
        end
        class << self
          def unique_keys(v)
            [:image,v[:id]]
          end

          def relative_distinguished_name(v)
            v[:id]
          end
        end
      end
    end
  end
end

