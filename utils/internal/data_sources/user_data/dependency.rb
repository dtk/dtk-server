module XYZ
  module DSNormalizer
    class UserData
      class Dependency < Top
        definitions do
          [:display_name, :type, :search_pattern, :description, :severity].each do |k|
            target[k] = fn(k,source)
          end
        end

        def self.relative_distinguished_name(source)
          source[:ref]
        end

        def self.display_name(source)
          source["display_name"]
        end

        def self.type(source)
          ret = source["type"] || ("component" if source["required_component"])
          raise Error.new("unexpected form for chef dependency") unless ret
          ret
        end

        def self.severity(source)
          source["severity"] || type(source) == "component" ? "warning" : "error"
        end

        def self.search_pattern(source)
          return source["search_pattern"] if source["search_pattern"]
          component = source["required_component"]
          raise Error.new("unexpected form for userdata dependency") unless component
          XYZ::Constraints::Macro::RequiredComponent.search_pattern(component)
        end

        def self.description(source)
          return source["description"] if source["description"]
          required_cmp = source["required_component"]
          base_cmp = source["parent_display_name"]
          raise Error.new("unexpected form for userdata dependency") unless required_cmp && base_cmp
          XYZ::Constraints::Macro::RequiredComponent.description(required_cmp,base_cmp)
        end
      end
    end
  end
end

