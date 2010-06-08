require File.expand_path("chef", File.dirname(__FILE__))
module XYZ
  module DSAdapter
    class Chef
      class Component < Chef::Top 
       private

        #TBD below is effectively dsl; may make more declarative using data integration dsl
        def unique_keys(v)
          [v["name"]]
        end

#Is v 'value'?
        def relative_distinguished_name(v)
          v["name"]
        end

#Whats going on here?
        def filter(v)
          attrs = %w{name display_name description chef_recipe attributes}
          HashObject.object_slice(v["metadata"],attrs)
        end

        def normalize(v)
          m = v["metadata"]
          name = v["name"] || m["display_name"] || m["name"]
          ret = {
            :display_name => name,
            :description => v["description"],
            :external_type => "chef_recipe",
            :external_cmp_ref => "recipe[#{name}]"
          }

          attrs = Hash.new
          (m["attributes"]||[]).each do |recipe_ref,av|
            #to strip of recipe name prefix if that is the case
            ref_imploded = recipe_ref.split("/")
            ref_x = (ref_imploded[0] == m["name"] and ref_imploded.size > 1) ? 
                ref_imploded[1..ref_imploded.size-1].join("/") : recipe_ref
            ref = ref_x.gsub(/\//,"__")
            external_attr_ref = "node[#{m["name"]}][#{ref_x.gsub(/\//,"][")}]"

            data_type = case av["type"]
              when "hash", "array"
                "json"
              else
                av["type"]
            end

            attrs[ref] ||= Hash.new
            %w{port_type display_name description constraints}.each do |k|
              attrs[ref][k.to_sym] = av[k] if av[k]
            end
            attrs[ref][:value_asserted] = av["default"] if av["default"]
            attrs[ref][:external_attr_ref] = external_attr_ref
            attrs[ref][:semantic_type] = av["semantic_type"].to_json if av["semantic_type"]
            attrs[ref][:data_type] = data_type
          end
          ret[:attribute] = attrs
          ret
        end
      end
    end
  end
end

