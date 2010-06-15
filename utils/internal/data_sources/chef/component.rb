require File.expand_path("chef", File.dirname(__FILE__))
module XYZ
  module DSAdapter
    class Chef
      class Component < Chef::Top 
       private
         definitions do
           source_complete_for_entire_target
           #TBD: current solution needed '= definition' or using dup every time refer to defined var like 'emtadata'; is there a better way (i.e., more transparant) to do this
           metadata = definition source["metadata"]
           name = definition fn(lambda{|x,y,z|x||y||z},source["name"],metadata["display_name"],metadata["name"])
           target[:display_name] = name
           target[:description] = source["description"]
           target[:external_type] = "chef_recipe"
           target[:external_cmp_ref] = fn(lambda{|name|"recipe[#{name}]"},name)

           prefix = target[:attributes] 
           each(metadata["attributes"]) do |recipe_ref,av|
             prefix[recipe_ref] = {}
           end
=begin
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
=end
        end

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

      end
    end
  end
end

