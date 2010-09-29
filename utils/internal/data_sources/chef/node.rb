module XYZ
  module DSNormalizer
    class Chef
      class Node < Top 
        definitions do
          target[:display_name] = source["node_name"]
          target[:tag] = if_unset(source["node_display_name"]) 
          if_exists(source["lsb"]) do
            target["os"] = source["lsb"]["description"]
          end
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
