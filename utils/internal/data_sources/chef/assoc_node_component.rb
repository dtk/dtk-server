require File.expand_path("chef", File.dirname(__FILE__))
module XYZ
  module DSAdapter
    class Chef
      class AsssocNodeComponent < Chef::Top 
       private

        #TBD below is effectively dsl; may make more declarative using data integration dsl
        def unique_keys(v)
          [v["node_name"],v["recipe_name"]]
        end

        def relative_distinguished_name(v)
          v["node_name"] + "__" + v["recipe_name"]
        end

        def normalize(v)
        end
      end
    end
  end
end
