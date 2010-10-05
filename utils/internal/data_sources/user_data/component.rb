module XYZ
  module DSNormalizer
    class UserData
      class Component < Top 
        definitions do
          target[:display_name] = source["ref"]
          target[:ui] = source["ui"]
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
