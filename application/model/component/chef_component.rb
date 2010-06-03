require DATA_SOURCE_ADAPTERS_DIR + 'chef'
module XYZ
  module DSAdapter
    class Chef
      class Component < Chef::Top 
        class << self
          def discover_and_update(container_id_handle,ds_object)
            #cookbooks = get_cookbook_list()
            cookbooks = %w{pg_pool postgresql}
            component_templates = cookbooks.map{|cb|cb.get_cookbook_metadata()}
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
	       ret[attr_ref][ref] = {
	         :display_name => av["display_name"],
	         :value_asserted => av["default"],
                 :constraints => av["constraints"],
	         :external_attr_ref => recipe_ref.to_s,
	         :port_type => av["port_type"],
	         :semantic_type => av["semantic_type"] ?  av["semantic_type"].to_json : nil,
	         :data_type => data_type,
	         :display_name => av["display_name"],
	         :description => av["description"],
	         :default => av["default"],
                 :constraints => av["constraints"]
              }
	    end
            ret
          end

          def unique_key_fields
            [:name]
          end
          def name_fields
            [:name]
          end
        end
      end
    end
  end
end

