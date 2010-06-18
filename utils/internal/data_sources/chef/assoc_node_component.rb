module XYZ
  module DSNormalizer
    class Chef
      class AssocNodeComponent < Top 
        definitions do
=begin
#Not right; may change forign key so it disambiguates when processing it using find_foreign_key_id

          target[:node_id] = foreign_key fn(lambda{|x|"/node/#{x}"},source["node_name"])
          target[:component_id] = foreign_key fn(lambda{|x|"/component/#{x}"},source["recipe_name"])
=end
        end
        class << self
          def unique_keys(source_hash)
            [source_hash["node_name"],source_hash["recipe_name"]]
          end

          def relative_distinguished_name(source_hash)
            source_hash["node_name"] + "__" + source_hash["recipe_name"]
          end
=begin
          def normalize(source_hash)
             #TND: :node_id is building in assumption that node_name matches ec2 name
             #This is just a stub; we need a more principlaed way to handle cross model correlation
            {:node_id => find_foreign_key_id(:node,[source_hash["node_name"]],:ec2),
              :component_id => find_foreign_key_id(:component,[source_hash["recipe_name"]])}
          end
=end
        end
      end
    end
  end
end
