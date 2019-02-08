#
# Copyright (C) 2010-2017 dtk contributors
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
module DTK; class  Assembly
  class Instance
    module DeleteByPath
      require_relative('delete_by_path/components')
      require_relative('delete_by_path/actions')

      def delete_by_path(path)
        delete_adapter, params = ret_adapter_and_params_from_path(path)
        delete_class = load_adapter_class(Module.nesting.first, delete_adapter)

        raise ErrorUsage, "Unexpected that delete adapter #{delete_class} does not implement delete method!" unless delete_class.respond_to?(:delete)

        delete_class.delete(self, params)
      end
    end
  end
end;end