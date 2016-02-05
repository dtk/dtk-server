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
module XYZ
  module ComponentType
    class Database < ComponentTypeHierarchy
      def self.clone_db_onto_db_server_node(db_server_node, db_server_component)
        base_sp_hash = {
          model_name: :component,
          filter: [:eq, :id, db_server_component[:ancestor_id]],
          cols: [:id, :library_library_id]
        }
        join_array =
          [{
             model_name: :attribute,
             join_type: :inner,
             alias: :db_component_name,
             filter: [:eq, :display_name, 'db_component'],
             join_cond: { component_component_id: :component__id },
             cols: [:value_asserted, :component_component_id]
           },
           {
             model_name: :component,
             alias: :db_component,
             join_type: :inner,
             convert: true,
             join_cond: { display_name: :db_component_name__value_asserted, library_library_id: :component__library_library_id },
             cols: [:id, :display_name, :library_library_id]
         }
          ]

        rows = Model.get_objects_from_join_array(db_server_component.model_handle, base_sp_hash, join_array)
        db_component = rows.first && rows.first[:db_component]
        unless db_component
          Log.error('Cannot find the db component associated with the db server')
          return nil
        end
        new_db_cmp_id = db_server_node.clone_into(db_component)
        db_server_component.model_handle.createIDH(id: new_db_cmp_id)
      end
    end
  end
end