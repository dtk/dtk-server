module Ramaze::Helper
  module NodeGroupHelper
    def create_obj(id_or_name_param)
      super(id_or_name_param, ::DTK::NodeGroup)
    end
  end
end
