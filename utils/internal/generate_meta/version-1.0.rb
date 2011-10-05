module XYZ
  module V1_0
    class ModuleMeta < ::XYZ::ModuleMeta
    end
    class ComponentMeta < ::XYZ::ComponentMeta
      def initialize(component_ps,context)
        super(context)
        set_hash_key(component_ps[:name])
        self[:display_name] = t(component_ps[:name])
        self[:description] = unknown
      end
    end
    class AttributeMeta < ::XYZ::AttributeMeta
    end
  end
end
