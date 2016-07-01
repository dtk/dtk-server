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
module DTK
  class CommonModule::Import::ServiceModule
    module Assembly
      module Nodes
        def self.db_update_hash(container_idh, assembly_ref, parsed_nodes, node_bindings_hash, component_module_refs, opts = {})
          # parsed_attributes.inject(DBUpdateHash.new) do |h, parsed_attribute|
          #   attr_name    = parsed_attribute.req(:Name)
          #   attr_val     = parsed_attribute.val(:Value)
          #   attr_content = {
          #     'display_name'   => attr_name,
          #     'value_asserted' => attr_val,
          #     'data_type'      => Attribute::Datatype.datatype_from_ruby_object(attr_val)
          #   }
          #   h.merge(attr_name => attr_content)
          # end
          # compute node_to_nb_rs and nb_rs_to_id
        end
      end
    end
  end
end
