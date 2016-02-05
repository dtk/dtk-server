#
# Copyright (C) 2010-2016 dtk contributors
#
# This file is part of the dtk project.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
module Ramaze::Helper
  module NodeHelper
    def ret_node_subtype_class
      subtype = ret_node_params_subtype()
      if subtype == :template
        ::DTK::Node::Template
      else
        ::DTK::Node
      end
    end

    def ret_nodes_by_subtype_class(model_handle, opts = {})
      subtype = ret_node_params_subtype()
      if subtype == :template
        ::DTK::Node::Template.list(model_handle, opts)
      else
        if (opts[:is_list_all] == 'true')
          ::DTK::Node.list(model_handle, opts)
        else
          ::DTK::Node.list_wo_assembly_nodes(model_handle)
        end
      end
    end

    def ret_node_params_subtype
      (ret_request_params(:subtype) || :instance).to_sym
    end

    def create_node_obj(id_param)
      create_obj(id_param, ::DTK::Node)
    end

    def create_node_template_obj(id_param)
      create_obj(id_param, ::DTK::Node::Template)
    end

    def ret_node_params_object_and_subtype
      [create_obj(:node_id, ret_node_subtype_class()), ret_node_params_subtype()]
    end
  end
end