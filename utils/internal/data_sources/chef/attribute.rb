module XYZ
  module DSNormalizer
    class Chef
      class Attribute < Top
         definitions do
           target[:external_attr_ref] = "stub" #"node[#{m["name"]}][#{ref_x.gsub(/\//,"][")}]"
           #TBD: put insomething like target[:external_attr_ref] = fn(lambda{|name,ref|"node[#{name}][#{ref.gsub(/\//,"][")}]"},source_parent["name"],source[])
           target[:data_type] = fn(lambda{|x|case x;when "hash", "array"; "json"; else x; end},source[][:type])
           #TBD: have form that is no assignment if source is null
           %w{port_type display_name description constraints}.each do |k|
             target[k.to_sym] = source[][k]
           end
           target[:value_asserted] = source[]["default"] 
           #TBD: put back in target[:semantic_type] = av["semantic_type"].to_json if av["semantic_type"]
         end

         class << self
           def unique_keys(source_hash)
            [relative_distinguished_name(source_hash)]
           end

           def relative_distinguished_name(source_hash)
            #TBD: assume if attr_ref.split("/").size > 1 then first is cookbookname
            ref = source_hash.keys.first
            ref_imploded = ref.split("/")
            return "default" unless ref_imploded.size > 1 
            ref_imploded[1..ref_imploded.size-1].join("__")
          end

          def filter(source_hash)
            HashObject.new()
          end
        end
      end
    end
  end
end

