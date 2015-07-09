module XYZ
  module DSNormalizer
    class Chef
      class ComponentInstance < Top
        definitions do
          target[:type] = 'instance'
          target[:basic_type] = fn(:basic_type,source['basic_type'])
          target[:component_type] = fn(:component_type,source)
          target[:display_name] = fn(:display_name,source)
          target[:description] = source['description']
          target[:external_ref] = fn(:external_ref,source['recipe_name'],source['node_name'])

          nested_definition :attribute, source['attributes']
        end

        class << self
          def unique_keys(source)
            [:instance,source['normalized_recipe_name']]
          end

          def relative_distinguished_name(source)
            source['normalized_recipe_name']
          end

          def display_name(source)
            source['normalized_recipe_name']
          end

          def component_type(source)
            source['normalized_recipe_name']
          end

          def external_ref(recipe_name,node_name)
            {'type' => 'chef_recipe_instance', 'recipe_name' => recipe_name, 'node_name' => node_name}
          end

          def basic_type(basic_type)
            return basic_type unless basic_type.is_a?(Hash)
            basic_type.keys.first
          end
        end
      end
    end
  end
end
