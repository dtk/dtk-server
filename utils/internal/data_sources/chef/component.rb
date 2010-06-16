module XYZ
  module DSNormalizer
    class Chef
      class Component < Top
        definitions do
          source_complete_for_entire_target
          #TBD: current solution needed '= definition' or using dup every time refer to defined var like 'emtadata'; is there a better way (i.e., more transparant) to do this
          metadata = definition source["metadata"]
          name = definition fn(lambda{|x,y,z|x||y||z},source["name"],metadata["display_name"],metadata["name"])
          target[:display_name] = name
          target[:description] = source["description"]
          target[:external_type] = "chef_recipe"
          target[:external_cmp_ref] = fn(lambda{|name|"recipe[#{name}]"},name)

          nested_definition :attribute, source["metadata"]["attributes"]
        end

        class << self
        #TBD below is effectively dsl; may make more declarative using data integration dsl
        def unique_keys(source_hash)
          [source_hash["name"]]
        end

        def relative_distinguished_name(source_hash)
          source_hash["name"]
        end
=begin
        def filter(source_hash)
          attrs = %w{name display_name description chef_recipe attributes}
          HashObject.object_slice(source_hash["metadata"],attrs)
        end
=end
        def filter(source_hash)
          HashObject.new()
        end
        end
      end
    end
  end
end
