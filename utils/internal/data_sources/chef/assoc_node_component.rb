module XYZ
  module DSNormalizer
    class Chef
      class AssocNodeComponent < Top 
        definitions do
          target[:node_id] = foreign_key :node, source["node_name"]
          component_ref = fn(lambda{|x,y|x+ "__" + y},source["node_name"],source["recipe_name"])
          target[:component_id] = foreign_key :component, component_ref
        end
        class << self
          def unique_keys(source)
            [source["node_name"],source["recipe_name"]]
          end

          def relative_distinguished_name(source)
            source["node_name"] + "__" + source["recipe_name"]
          end
        end
      end
    end
  end
end
