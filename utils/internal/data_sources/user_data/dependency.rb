module XYZ
  module DSNormalizer
    class UserData
      class Dependency < Top
        definitions do
          target[:display_name] = source[:ref]
          target[:type] = "component"
          target[:search_pattern] = fn(:search_pattern,source)
          target[:description] = fn(:description,source)
        end

        def self.relative_distinguished_name(source)
          source[:ref]
        end

        def self.search_pattern(source)
          return source["search_pattern"] if source["search_pattern"]
          component = source["required_component"]
          raise Error.new("unexpected form for userdata dependency") unless component
          XYZ::Constraints::Macro.required_component(component)
        end
        def self.description(source)
          return source["description"] if source["description"]
          component = source["required_component"]
          raise Error.new("unexpected form for userdata dependency") unless component
          i18n_name = Model.i18n_string(component_i18n,:component,component)
          "#{i18n_name || component.split(name_delimiter()).map{|x|x.capitalize()}.join(" ")} is required"
        end
        def self.component_i18n()
          @@component_i18n ||= Model.get_i18n_mappings_for_models(:component)
        end
      end
    end
  end
end

