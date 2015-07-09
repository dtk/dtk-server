module XYZ
  module DSNormalizer
    class Chef
      class Attribute < Top
        definitions do
          # TBD: assuming that after split first item is cookbook name
          target[:external_ref] = fn(:external_ref, source)
          target[:display_name] = fn(:display_name, source)
          target[:data_type] = fn(:data_type, source)
          target[:is_port] = source['is_port']
          target[:description] = source['description']
          target[:output_variable] = source['calculated']
          target[:required] = fn(:required, source['required'])
          target[:value_asserted] = fn(lambda { |x, y| x || y }, source['value'], source[]['default'])
          target[:semantic_type] = fn(:semantic_type, source['semantic_type'])
          target[:semantic_type_summary] = fn(:semantic_type_summary, source['semantic_type'])
          if_exists(source['dependency']) do
            nested_definition :dependency, source['dependency']
          end
        end

        def self.filter_raw_source_objects(_source)
          DBUpdateHash.new()
        end

        def self.relative_distinguished_name(source)
          split = source[:ref].split('/')
          split.shift if split.size > 1
          split.join(name_delimiter())
        end

        #### defined and helper fns
        def self.display_name(source)
          split = source[:ref].split('/')
          split.shift if split.size > 1
          split.join(name_delimiter())
        end

        def self.external_ref(source)
          prefix = source[:service_name] ? "service[#{source[:service_name]}]" : "node[#{source[:ref].split('/').first}]"
          path = prefix + name_suffix(source)

          if source[:service_name]
            { :type => 'service_attribute', 'path' => path }
          else
            { :type => 'chef_attribute', 'path' => path }
          end
        end

        def self.name_suffix(source)
          x = source[:ref].split('/'); x.shift
          "[#{x.join('][')}]"
        end

        def self.semantic_type(semantic_type)
          (semantic_type.is_a?(Array) || semantic_type.is_a?(Hash)) ? semantic_type.to_json : semantic_type
        end

        def self.semantic_type_summary(semantic_type)
          return nil if semantic_type.nil?
          return semantic_type unless semantic_type.is_a?(Hash)
          key = semantic_type.keys.first
          return nil if key.empty?
          key.to_s =~ /^:/ ? semantic_type_summary(semantic_type.values.first) : key
        end

        def self.required(required_value)
          return nil if required_value.nil?
          return true if %w{true required}.include?(required_value.to_s)
          return false if %w{false recommended optional}.include?(required_value.to_s)
          nil
        end
        def self.data_type(source)
          return source['data_type'] if source['data_type']
          type = source['type']
          case type
           when 'hash', 'array'
            'json'
           else type
          end
        end
      end
    end
  end
end
