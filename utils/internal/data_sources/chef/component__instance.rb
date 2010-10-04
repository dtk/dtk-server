module XYZ
  module DSNormalizer
    class Chef
      class ComponentInstance < Top
        definitions do
          target[:type] = "instance"
          target[:basic_type] = source["basic_type"]
          target[:display_name] = source[:ref]
          target[:description] = source["description"]
          target[:external_type] = "chef_recipe"
          target[:external_cmp_ref] = fn(lambda{|recipe_name|"recipe[#{recipe_name}]"},source[:ref])

          nested_definition :attribute, source["attributes"]
        end

        class << self
          def unique_keys(source)
            [:instance,source[:ref]]
          end

          def relative_distinguished_name(source)
            source[:ref]
          end

        end
      end
    end
  end
end
