module XYZ
  module DSNormalizer
    class UserData
      class Component < Top 
        definitions do
          target[:display_name] = source["ref"]
          target[:ui] = source["ui"]
          if_exists(source["only_one_per_node"]) do
            target[:only_one_per_node] = source["only_one_per_node"]
          end
          if_exists(source["basic_type"]) do
            target[:basic_type] = source["basic_type"]
          end
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
