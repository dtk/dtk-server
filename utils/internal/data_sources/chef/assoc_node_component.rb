require File.expand_path("chef", File.dirname(__FILE__))
module XYZ
  module DSAdapter
    class Chef
      class AssocNodeComponent < Chef::Top 
       private
        def unique_keys(v)
          [v["node_name"],v["recipe_name"]]
        end

        def relative_distinguished_name(v)
          v["node_name"] + "__" + v["recipe_name"]
        end

        def normalize(v)
     require 'pp'; pp [:find_foreign_key_id,find_foreign_key_id(:component,[v["recipe_name"]])]
          {}
        end
      end
    end
  end
end
