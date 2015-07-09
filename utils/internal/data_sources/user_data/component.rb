module XYZ
  module DSNormalizer
    class UserData
      class Component < Top
        definitions do
          target[:display_name] = source['ref']
          target[:basic_type] = fn(:basic_type,source)
          (column_names(:component) - [:display_name,:basic_type]).each do |v|
            if_exists(source[v.to_s]) do
              target[v.to_sym] = source[v.to_s]
            end
          end
          if_exists(source['attribute']) do
            nested_definition :attribute, source['attribute']
          end
          if_exists(source['dependency']) do
            nested_definition :dependency, fn(:dependency,source)
          end
        end
        def self.unique_keys(source)
          [source['qualified_ref']]
        end

        def self.dependency(source)
          dep = source['dependency']
          dep.inject({}){|h,kv|h.merge(kv[0] => kv[1].merge('parent_display_name' => source['ref']))}
        end

        def self.relative_distinguished_name(source)
          source['ref']
        end

        def self.basic_type(source)
          # TODO: assumes that user_data has all basic types specfic types
          return source['basic_type'] if source['basic_type']
          if source['specific_type']
            basic_type = ComponentTypeHierarchy.basic_type(source['specific_type'])
            basic_type && basic_type.to_s
          end
        end
      end
    end
  end
end
