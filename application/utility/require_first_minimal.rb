##### temp until convert to DTK
module XYZ
end
DTK = XYZ

module DTK
  module BaseDir
    system_root_path = File.expand_path('../../', File.dirname(__FILE__))
    Lib = "#{system_root_path}/lib"
    App = "#{system_root_path}/application"
    Utils = "#{system_root_path}/utils/internal"

    require File.expand_path("#{App}/require_first", File.dirname(__FILE__))
    dtk_require_common_library()
    dtk_nested_require(Lib, 'configuration')
    dtk_nested_require(Utils, 'aux')
  end
end

   
