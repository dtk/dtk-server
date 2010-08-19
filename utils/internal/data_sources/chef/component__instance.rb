module XYZ
  module DSNormalizer
    class Chef
      class ComponentInstance < Top
        definitions do
          target[:type] = "instance"
        end

        class << self
          #TBD below is effectively dsl; may make more declarative using data integration dsl
          def unique_keys(source_hash)
            [:instance,source_hash["name"]]
          end

          def relative_distinguished_name(source_hash)
            source_hash["name"]
          end

          def filter(source_hash)
            attrs = %w{name display_name description chef_recipe}
            DBUpdateHash.object_slice(source_hash["metadata"],attrs)
          end
        end
      end
    end
  end
end
