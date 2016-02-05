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
module DTK; class AttributeLink::UpdateDelta::Delete
  class Index
    class Null < self
      # called when the last index being removed
      def process!
        input_attribute = @link_info.input_attribute
        row_to_update = {
          id: input_attribute[:id],
          value_derived: nil
        }
        Model.update_from_rows(@attr_mh, [row_to_update])
        old_value_derived = input_attribute[:value_derived]
        row_to_update.merge(old_value_derived: old_value_derived)
      end
    end
  end
end; end