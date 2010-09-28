module XYZ
  module DSNormalizer
    class Chef
      class Node < Top 
        definitions do
          target[:display_name] = source["node_name"]
          target[:tag] = source["node_display_name"]
        end
        class << self
          def relative_distinguished_name(source)
            source["node_name"] 
          end
        end
      end
    end
  end
end
