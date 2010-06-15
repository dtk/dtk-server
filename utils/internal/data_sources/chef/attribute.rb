require File.expand_path("chef", File.dirname(__FILE__))
module XYZ
  module DSAdapter
    class Chef
      class Attribute < Chef::Top 
       private
         definitions do
           target[:external_attr_ref] = "stub" #"node[#{m["name"]}][#{ref_x.gsub(/\//,"][")}]"
           target[:data_type] = fn(lambda{|x|case x;when "hash", "array"; "json"; else x; end},source[:type])
           #TBD: have form that is no assignment if source is null
           %w{port_type display_name description constraints}.each do |k|
             target[k.to_sym] = source[k]
           end
           target[:value_asserted] = source["default"] 
           #TBD: put back in target[:semantic_type] = av["semantic_type"].to_json if av["semantic_type"]
         end

        #TBD below is effectively dsl; may make more declarative using data integration dsl
        def unique_keys(source_hash)
          [relative_distinguished_name(source_hash)]
        end

        def relative_distinguished_name(source_hash)
          #TBD: assume if attr_ref.split("/").size > 1 then first is cookbookname
          ref_imploded = source_hash["ref"].split("/")
          return ref_imploded.first unless ref_imploded.size > 1 
          ref_imploded.shift.join("__")
        end

        def filter(v)
          HashObject.new()
        end
      end
    end
  end
end

