module XYZ
  module DSNormalizer
    class Chef
      class Attribute < Top
        definitions do
          #TBD: assuming that after split first item is cookbook name
          target[:external_attr_ref] = fn(:external_attr_ref,source)
          target[:data_type] = fn(:data_type,source[]["type"])
          #TBD: have form that is no assignment if source is null
          %w{port_type description constraints}.each do |k|
            target[k.to_sym] = source[][k]
          end
#         target[:value_asserted] = fn(lambda{|x,y|x||y},source[]["value"],source[]["default"])
          target[:value_asserted] = fn(:value_asserted,source)
          target[:semantic_type] = fn(lambda{|x|x.to_json if x},source[]["semantic_type"])
        end

         class << self
           def unique_keys(source_hash)
            [relative_distinguished_name(source_hash)]
           end

           def relative_distinguished_name(source_hash)
             external_attr_ref(source_hash)
          end

          def filter(source_hash)
            DBUpdateHash.new()
          end

          #### defined fns
          def external_attr_ref(source_hash)
             ref = source_hash.keys.first
             if ref.first =~ /^_service/
               "service[#{ref.gsub(/^_service\//,"").gsub(/\//,"][")}]"
             else
               "node[#{ref.gsub(/\//,"][")}]"
             end
          end

         def value_asserted(source_hash)
           vals = source_hash.values.first
           return nil unless vals
           value_asserted = vals["value"]||vals["default"]
           return nil unless value_asserted
           (value_asserted.kind_of?(Hash) or value_asserted.kind_of?(Array)) ? JSON.pretty_generate(value_asserted) : value_asserted
         end
          def data_type(type)
            case type
              when "hash", "array"
                "json"
              else type
            end
          end
        end
      end
    end
  end
end

