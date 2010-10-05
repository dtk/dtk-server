module XYZ
  module DSNormalizer
    class Chef
      class ComponentRecipe < Top
        definitions do
          target[:type] = "template"
          target[:basic_type] = source["basic_type"]
          name = source["recipe_name"]
          target[:display_name] = name
          target[:description] = source["description"]
          target[:external_ref] = fn(:external_ref,name)
          nested_definition :monitoring_item, source["monitoring_items"]
          nested_definition :attribute, source["attributes"]
        end

        class << self
          def unique_keys(source)
            [:template,source["recipe_name"]]
          end

          def relative_distinguished_name(source)
            source["recipe_name"]
          end
          def external_ref(recipe_name)
            {"type" => "chef_recipe", "recipe_name" => recipe_name}
          end
        end
      end
    end
  end
end
