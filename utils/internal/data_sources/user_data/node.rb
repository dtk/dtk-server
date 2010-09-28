module XYZ
  module DSNormalizer
    class UserData
      class Node < Top 
        definitions do
          target[:display_name] = source["ref"]
          target[:tag] = source["tag"]
        end
         class << self
           def relative_distinguished_name(source)
             source["ref"]
           end
         end
      end
    end
  end
end
