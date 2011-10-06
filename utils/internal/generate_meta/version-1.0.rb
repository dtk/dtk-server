#TODO: modify for that the abstract classes do what is below and the hash_render fn is what makes teh difference;
#this is because dont want to modify interface to front end
module XYZ
  module V1_0
    class ModuleMeta < ::XYZ::ModuleMeta
    end
    class ComponentMeta < ::XYZ::ComponentMeta
    end
    class  DependencyMeta < ::XYZ::AttributeMeta
    end
    class AttributeMeta < ::XYZ::AttributeMeta
    end
  end
end
