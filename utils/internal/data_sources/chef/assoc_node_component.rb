module XYZ
  module DSNormalizer
    class Chef
      class AssocNodeComponent < Top 
       private
        class << self
          def unique_keys(v)
            [v["node_name"],v["recipe_name"]]
          end

          def relative_distinguished_name(v)
            v["node_name"] + "__" + v["recipe_name"]
          end

          def normalize(v)
             #TND: :node_id is building in assumption that node_name matches ec2 name
             #This is just a stub; we need a more principlaed way to handle cross model correlation
            {:node_id => find_foreign_key_id(:node,[v["node_name"]],:ec2),
              :component_id => find_foreign_key_id(:component,[v["recipe_name"]])}
          end
        end
      end
    end
  end
end
