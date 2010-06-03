require File.expand_path("chef", File.dirname(__FILE__))
module XYZ
  module DSAdapter
    class Chef
      class Component < Chef::Top 
        class << self
         private
          #TBD below is effectively dsl; may make more declarative using data integration dsl
          def object_paths
            %w{/cookbooks /cookbooks/$1/metadata}
          end
          def filter_attributes
            %w{name display_name description chef_recipe attributes}
          end
          def normalize(v)
            ret =
	      {:display_name => v["display_name"] ? v["display_name"] : v["name"],
	       :description => v["description"],
	       :external_type => "chef_recipe",
               :external_cmp_ref => v["name"]} 

            attrs = Hash.new
	    (v["attributes"]||[]).each do |recipe_ref,av|
	       #to strip of recipe name prefix if that is the case
	       ref_imploded = recipe_ref.split("/")
	       ref = (ref_imploded[0] == v["name"] and ref_imploded.size > 1) ? 
	         ref_imploded[1..ref_imploded.size-1].join("/") : recipe_ref
	       data_type = case av["type"]
	         when "hash", "array"
	           "json"
	         else
	           av["type"]
	       end
               attrs[ref] ||= Hash.new
               %w{constraints port_type display_name description constraints}.each do |k|
	         attrs[ref][k.to_sym] = av[k] if av[k]
               end
	       attrs[ref][:value_asserted] = av["default"] if av["default"]
	       attrs[ref][:external_attr_ref] = recipe_ref.to_s
	       attrs[ref][:semantic_type] = av["semantic_type"].to_json if av["semantic_type"]
	       attrs[ref][:data_type] = data_type
	    end
            ret[:attribute] = attrs
            ret
          end

          def unique_key_fields
            ["name"]
          end
          def name_fields
            ["name"]
          end
        end
      end
    end
  end
end

