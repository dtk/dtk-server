module XYZ
  module DSNormalizer
    class Chef
      class Attribute < Top
        definitions do
          #TBD: assuming that after split first item is cookbook name
          target[:external_ref] = fn(:external_ref,source)
          target[:display_name] = fn(:relative_distinguished_name,source)
          target[:data_type] = fn(:data_type,source["type"])
          #TBD: have form that is no assignment if source is null
          %w{port_type semantic_type description constraints}.each do |k|
            target[k.to_sym] = source[k]
          end
          target[:output_variable] = source["calculated"]
          target[:required] = fn(:required,source["required"])
          target[:value_asserted] = fn(lambda{|x,y|x||y},source["value"],source[]["default"])
          target[:semantic_type] = fn(lambda{|x|x.to_json if x},source["semantic_type"])
        end

         class << self
           def filter_raw_source_objects(source)
             DBUpdateHash.new()
           end

           def relative_distinguished_name(source)
             prefix = source[:service_name] ? "port" : "var"
             prefix+name_suffix(source)
           end

          #### defined and helper fns
          def external_ref(source)
            prefix = source[:service_name] ? "service[#{source[:service_name]}]" : "node[#{source[:ref].split("/").first}]"
            path = prefix+name_suffix(source)

            if source[:service_name]
              {:type => "service_attribute", "path" => path}
            else
              {:type => "chef_attribute", "path" => path}
            end
          end

          def name_suffix(source)
            x = source[:ref].split("/");x.shift
            "[#{x.join("][")}]"
          end
          
          def required(required_value)
            return nil if required_value.nil?
            return true if %w{true required}.include?(required_value.to_s)
            return false if %w{false recommended optional}.include?(required_value.to_s)
            nil
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

