module XYZ
  module DSNormalizer
    class Chef
      class AssocNodeComponent < Top 
        definitions do
          target[:node_id] = foreign_key :node, source["node_name"]
          target[:component_id] = foreign_key :component, source["recipe_name"]
        end
        class << self
          def unique_keys(source_hash)
            [source_hash["node_name"],source_hash["recipe_name"]]
          end

          def relative_distinguished_name(source_hash)
            source_hash["node_name"] + "__" + source_hash["recipe_name"]
          end
        end
      end
    end
  end
end
