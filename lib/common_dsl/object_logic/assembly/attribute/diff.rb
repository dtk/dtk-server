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
  class ObjectLogic::Assembly::Attribute
    class Diff < CommonDSL::Diff::Base
      class Modify < CommonDSL::Diff::Element::Modify
        def process(_result, _opts = {})
          # result does not need to be updated since attribute changes dont entail service-side
          # modification to dsl
          ::DTK::Attribute.update_and_propagate_attribute_from_diff(existing_object, new_val)
        end
      end
    end
  end
end; end
