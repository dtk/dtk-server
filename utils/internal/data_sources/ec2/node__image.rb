require File.expand_path("ec2", File.dirname(__FILE__))
module XYZ
  module DSNormalizer
    class Ec2
      class NodeImage < Top 
       private
        definitions do
          target[:type] = "image"
          target[:display_name] = source[:id]
        end
        class << self
          def unique_keys(source_hash)
            [:image,source_hash[:id]]
          end

          def relative_distinguished_name(source_hash)
            source_hash[:id]
          end
        end
      end
    end
  end
end

