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
  class CommonDSL::Diff
    class Element
      class Add < self
        attr_reader :parse_object
        # opts can have keys
        #  :parse_object
        def initialize(qualified_key, opts = {})
          super(qualified_key)
          @parse_object = opts[:parse_object]
        end

        def serialize(serialized_hash)
          serialized_hash.serialize_add_element(self)
        end

      end
    end
  end
end
