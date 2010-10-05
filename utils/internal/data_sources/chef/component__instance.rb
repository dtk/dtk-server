module XYZ
  module DSNormalizer
    class Chef
      class ComponentInstance < Top
        definitions do
          target[:type] = "instance"
          target[:basic_type] = source["basic_type"]
          target[:display_name] = source[:ref]
          target[:description] = source["description"]
          target[:external_ref] = fn(:external_ref,source[:ref],source["node_name"])

          nested_definition :attribute, source["attributes"]
        end

        class << self
          def unique_keys(source)
            [:instance,source[:ref]]
          end

          def relative_distinguished_name(source)
            source[:ref]
          end

          def external_ref(recipe_name,node_name)
            {"type" => "chef_recipe_instance", "recipe_name" => recipe_name, "node_name" => node_name} 
          end
        end
      end
    end
  end
end
