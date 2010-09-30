module XYZ
  module DSNormalizer
    class UserData
      class Node < Top 
        definitions do
          target[:display_name] = source["ref"]
          target[:tag] = source["tag"]
          target[:disk_size] = source["disk_size"]
        end
         class << self
            def unique_keys(source)
              [source["qualified_ref"]]
            end

           def relative_distinguished_name(source)
             source["ref"]
           end
         end
      end
    end
  end
end
