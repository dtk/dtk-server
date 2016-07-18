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
module DTK; module CommonModule::DSL::Generate
  class ContentInput 
    class Assembly
      class Attribute < ContentInput::Hash
        def self.generate_content_input(attributes)
          ret = ContentInput::Array.new
          attributes.each { |attribute| ret << new.generate_content_input!(attribute) }
          ret
        end
        
        def generate_content_input!(attribute)
          set(:Name, attribute.display_name)
          set(:Value, attribute[:attribute_value])
          add_tags?(tags?(attribute))
          self
        end

        private

        def tags?(attribute)
          # TODO: stub
          :foo
        end

      end
    end
  end
end; end
