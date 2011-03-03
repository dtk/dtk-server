module XYZ
  module DSNormalizer
    class UserData
      class Component < Top 
        definitions do
          target[:display_name] = source["ref"]
          (column_names(:component) - [:display_name]).each do |v|
            if_exists(source[v.to_s]) do
              target[v.to_sym] = source[v.to_s]
            end
          end
          if_exists(source["attribute"]) do
            nested_definition :attribute, source["attribute"]
          end
          if_exists(source["dependency"]) do
            nested_definition :dependency, source["dependency"]
          end
        end
        def self.unique_keys(source)
          [source["qualified_ref"]]
        end

        def self.relative_distinguished_name(source)
          source["ref"]
        end
      end
    end
  end
end
