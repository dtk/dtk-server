module XYZ
  module DSNormalizer
    class Chef
      class ComponentRecipe < Top
        definitions do
          target[:type] = "instance"
          target[:basic_type] = fn(:basic_type,source["basic_type"])
          name = source["recipe_name"]
          target[:component_type] = fn(:component_type,name)
          target[:display_name] = fn(:display_name,name)
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
            source["recipe_name"].gsub(/::/,name_delimiter())
          end
          def display_name(recipe_name)
            recipe_name.gsub(/::/,name_delimiter())
          end
          def component_type(recipe_name)
            recipe_name.gsub(/::/,name_delimiter())
          end
          def external_ref(recipe_name)
            {"type" => "chef_recipe", "recipe_name" => recipe_name}
          end
          def basic_type(basic_type)
            return basic_type unless basic_type.kind_of?(Hash)
            basic_type.keys.first
          end
        end
      end
    end
  end
end
