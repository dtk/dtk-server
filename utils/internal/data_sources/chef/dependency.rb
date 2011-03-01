module XYZ
  module DSNormalizer
    class Chef
      class Dependency < Top
        definitions do
          target[:display_name] = source[:ref]
          target[:description] = fn(:description,source["recipe_name"])
          target[:search_pattern] = fn(:search_pattern,source["recipe_name"])
        end

        def self.relative_distinguished_name(source)
          source[:ref]
        end
      end
    end
  end
end

