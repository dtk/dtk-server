require DATA_SOURCE_ADAPTERS_DIR + 'chef'
module XYZ
  module DSAdapter
    class Chef
      class Component < Chef::Top 
        class << self
          def discover_and_update(container_id_handle,ds_object)
            #cookbooks = get_cookbook_list()
            cookbooks = %w{pg_pool postgresql} #stub
            component_templates = cookbooks.map{|cb|get_cookbook_metadata(cb)}
            sync_with_discovered(container_id_handle,component_templates)
          end
         private
          #TBD below is effectively dsl; may make more declarative using data integration dsl
          def normalize(v)
            ret =
	      {:display_name => v["display_name"] ? v["display_name"] : v["name"],
	       :description => v["description"],
	       :external_type => "chef_recipe",
               :external_cmp_ref => v["name"]} 

	    (v["attributes"]||[]).each do |recipe_ref,av|
	       #to strip of recipe name prefix if that is the case
	       ref_imploded = recipe_ref.split("/")
	       attr_ref = ((ref_imploded[0] == v["name"] and ref_imploded.size > 1) ? 
	         ref_imploded[1..ref_imploded.size-1].join("/") : recipe_ref).to_sym
	       data_type = case av["type"]
	         when "hash", "array"
	           "json"
	         else
	           av["type"]
	       end
               ret[attr_ref] ||= Hash.new
               %w{constraints port_type display_name description constraints}.each do |k|
	         ret[attr_ref][k.to_sym] = av[k] if av[k]
               end
	       ret[attr_ref][:value_asserted] = av["default"] if av["default"]
	       ret[attr_ref][:external_attr_ref] = recipe_ref.to_s
	       ret[attr_ref][:semantic_type] = av["semantic_type"].to_json if av["semantic_type"]
	      ret[attr_ref][:data_type] = data_type
	    end
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

