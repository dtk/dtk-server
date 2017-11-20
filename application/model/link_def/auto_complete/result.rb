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
  class LinkDef::AutoComplete
    class Result 
      def initialize(base_aug_component, link_def)
        @base_aug_component = base_aug_component
        @link_def           = link_def
      end

      def severity_level
        fail Error, "This method should be overwritten by concrete class"
      end

      protected

      attr_reader :base_aug_component, :link_def

      def base_component_name
        @base_component_name ||= self.base_aug_component.display_name_print_form
      end

      def link_def_name
        @link_def_name ||= self.link_def.get_field?(:link_type)
      end

      class UniqueMatch < self
        def initialize(base_aug_component, link_def, matching_component)
          super(base_aug_component, link_def)
          @matching_component = matching_component
        end

        def severity_level
          :info
        end
      end

      class NoMatch < self
        # TODO: break this into case where there are stil matches outside of context given
        def initialize(base_aug_component, link_def)
          super(base_aug_component, link_def)
        end

        def severity_level
          :error
          # TODO: to test warnings
          :warning
        end

        def message
          ret = "There is no match for component '#{base_component_name}'"
          ret << " for link of type '#{link_def_name}'" if link_def_name
          ret
        end
      end

      class MultipleMatches < self
        def initialize(base_aug_component, link_def, matching_components)
          super(base_aug_component, link_def)
          @matching_components = matching_components
        end

        def severity_level
          :warning
        end

        def message
          # TODO: give info about exact which match
          "There are multple matches for component '#{base_component_name}'"
        end   
      end
      
    end
  end
end
