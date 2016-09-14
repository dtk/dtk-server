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
module DTK; module CommonDSL 
  class ObjectLogic::Assembly
    class Workflow::Diff
      class Delete < CommonDSL::Diff::Element::Delete
        include Mixin

        def process(_result, _opts = {})
          fail Diff::DiffErrors.new("The create workflow cannot be deleted", create_backup_file: true) if is_create_workflow?
          Model.delete_instance(workflow_id_handle)
          nil
        end

        private
        def workflow_id_handle
          id_handle
        end
      end
    end
  end
end; end
