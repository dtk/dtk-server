module XYZ
  module DSNormalizer
    class UserData
      class Attribute < Top
        definitions do
          target[:external_ref] = fn(:external_ref,source)
          target[:display_name] = fn(:display_name,source)
          (column_names(:attribute) - [:external_ref, :display_name]).each do |v|
            if_exists(source[v.to_s]) do
              target[v.to_sym] = source[v.to_s]
            end
          end
          if_exists(source["dependency"]) do
            nested_definition :dependency, source["dependency"]
          end
        end

        def self.relative_distinguished_name(source)
          source[:ref]
        end

        def self.display_name(source)
          source[:ref].split("/")
        end

        def self.external_ref(source)
          {type: "attribute", path: source[:ref]}
        end
      end
    end
  end
end
