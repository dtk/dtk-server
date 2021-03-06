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
  module CommonDSL::Generate
    class ContentInput
      class Array < ::DTK::DSL::FileGenerator::ContentInput::Array
        include DiffMixin
        extend DiffClassMixin

        def initialize
          super(ContentInput)
        end

        # Needed by any object that can be grouped as an array (as opposed to a hash)
        def diff_key
          fail Error::NoMethodForConcreteClass.new(self.class)
        end

      end
    end
  end
end
