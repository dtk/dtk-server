module XYZ
  module V1_0
    class ModuleMeta < ::XYZ::ModuleMeta
    end
    class ComponentMeta < ::XYZ::ComponentMeta
      def hash_render()
      end
    end
    class AttributeMeta < ::XYZ::AttributeMeta
      def hash_render()
      end
    end
  end
end
