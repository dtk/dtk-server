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
  class Assembly::Instance
    class DSLLocation < Model
      module Mixin
        def get_dsl_locations
          sp_hash = {
            cols: DSLLocation.common_columns,
            filter: [:eq, :component_component_id, id]
          }
          Model.get_objs(model_handle(:assembly_instance_dsl_location), sp_hash)
        end
      end

      def self.common_columns
        [:id, :display_name, :group_id, :component_component_id, :path]
      end
    end
  end
end
