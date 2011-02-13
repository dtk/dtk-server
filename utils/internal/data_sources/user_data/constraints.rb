module XYZ
  module DSNormalizer
    class UserData
      class Constraints < Top
        definitions do
          target[:display_name] = source[:ref]
          target[:component_constraints] = fn(:required_components,source["required_components"]) 
        end

        def self.relative_distinguished_name(source)
          source[:ref]
        end

        def self.required_components(component_list)
          XYZ::Constraints::Macro.required_components(component_list)
        end
      end
    end
  end
end

