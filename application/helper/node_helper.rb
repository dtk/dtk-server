module Ramaze::Helper
  module NodeHelper
    def ret_node_subtype_class()
      subtype = (ret_request_params(:subtype)||:instance).to_sym
      if subtype == :template
        ::DTK::Node::Template
      else
        ::DTK::Node
      end
    end
  end
end
