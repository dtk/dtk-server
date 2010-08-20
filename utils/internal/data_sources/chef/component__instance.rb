module XYZ
  module DSNormalizer
    class Chef
      class ComponentInstance < Top
        definitions do
          target[:type] = "instance"
          metadata = source["metadata"]
          recipe_name = source["recipe_name"]
          name = fn(lambda{|x,y|x+ "__" + y},source["node_name"],recipe_name)
          target[:display_name] = name
          target[:description] = source["description"]
          target[:external_type] = "chef_recipe"
          target[:external_cmp_ref] = fn(lambda{|recipe_name|"recipe[#{recipe_name}]"},recipe_name)

          nested_definition :attribute, source["metadata"]["attributes"]
        end

        class << self
          def unique_keys(source_hash)
            [:instance,source_hash["node_name"],source_hash["recipe_name"]]
          end

          def relative_distinguished_name(source_hash)
            source_hash["node_name"] + "__" + source_hash["recipe_name"]
          end

        end
      end
    end
  end
end
