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
    class Component::Diff
      class Delete < CommonDSL::Diff::Element::Delete
        include Mixin

        def process(_result, _opts = {})
          # TODO: DTK-2665: treat this. initilly may case on whether component has a dleet action in which case teh process can be a no op
          Diff::DiffErrors::ChangeNotSupported.raise_error(self.class, create_backup_file: true)
        end

      end
    end
  end
end; end
