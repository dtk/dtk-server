module XYZ
  module DSNormalizer
    class Chef
      class Attribute < Top
        definitions do
          #TBD: assuming that after split first item is cookbook name
          target[:external_ref] = fn(:external_ref,source)
          target[:display_name] = fn(:display_name,source)
          target[:data_type] = fn(:data_type,source["type"])
          target[:is_port] = source["is_port"]
          target[:description] = source["description"]
          target[:output_variable] = source["calculated"]
          target[:required] = fn(:required,source["required"])
          target[:value_asserted] = fn(lambda{|x,y|x||y},source["value"],source[]["default"])
          target[:semantic_type] = fn(lambda{|x|x.to_json if x},source["semantic_type"])
          target[:semantic_type_summary] = fn(:semantic_type_summary,source["semantic_type"])
        end

         class << self
           def filter_raw_source_objects(source)
             DBUpdateHash.new()
           end

           #TODO" use aux fns
           def relative_distinguished_name(source)
             split = source[:ref].split("/")
             split.join("][") + (split.size == 1 ? "" : "]")
           end

          #### defined and helper fns
           def display_name(source)
             split = source[:ref].split("/")
             split.shift if split.size > 1
             Aux.put_in_bracket_form(split)
           end

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
          
          def semantic_type_summary(semantic_type)
            return nil if semantic_type.nil?
            return semantic_type unless semantic_type.kind_of?(Hash)
            key = semantic_type.keys.first
            return nil if key.empty?
            key.to_s =~ /^:/ ? semantic_type_summary(semantic_type.values.first) : key
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

