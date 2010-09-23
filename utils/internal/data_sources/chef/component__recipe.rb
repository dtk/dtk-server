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
          target[:external_type] = "chef_recipe"
          target[:external_cmp_ref] = fn(lambda{|name|"recipe[#{name}]"},name)
          nested_definition :monitoring_item, source["monitoring_items"]
          nested_definition :attribute, source["attributes"]
        end

        class << self
          #TBD below is effectively dsl; may make more declarative using data integration dsl
          def unique_keys(source)
            [:template,source["recipe_name"]]
          end

          def relative_distinguished_name(source)
            source["recipe_name"]
          end
        end
      end
    end
  end
end
