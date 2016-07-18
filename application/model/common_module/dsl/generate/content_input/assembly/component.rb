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
      class Component < ContentInput::Hash
        def self.generate_content_input(aug_components)
          ret = ContentInput::Array.new
          aug_components.each { |aug_component| ret << new.generate_content_input!(aug_component) }
          ret
        end
        
        def generate_content_input!(aug_component)
          # TODO: stub
          merge!(aug_component)
          self
        end
      end
    end
  end
end; end
