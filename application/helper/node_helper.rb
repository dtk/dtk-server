module Ramaze::Helper
  module NodeHelper
    def ret_node_subtype_class()
      subtype = ret_node_params_subtype()
      if subtype == :template
        ::DTK::Node::Template
      else
        ::DTK::Node
      end
    end

    def ret_node_params_subtype()
      (ret_request_params(:subtype)||:instance).to_sym
    end

    def ret_node_params_object_and_subtype()
      [create_obj(:node_id,ret_node_subtype_class()),ret_node_params_subtype()]
    end
  end
end
