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
  class ConfigAgent::Adapter::Dynamic
    module ExecutionEnvironment
      # TODO: maybe to providers that treat breakpoint
      class BreakpointProcessing
        def initialize(dynamic_provider)
          @dynamic_provider = dynamic_provider
        end

        def self.process!(dynamic_provider)
          if breakpoint_class = breakpoint_class?(dynamic_provider)
            breakpoint_class.new(dynamic_provider).process!
          end
        end

        def process!
          Aux.fail_if_not_concrete(self)
        end

        protected

        attr_reader :dynamic_provider

        class Byebug < self
          GEMS_ATTRIBUTE = 'gems'
          BYEBUG_GEM     = 'byebug'

          def process!
            if gems_attribute = matching_attribute?(GEMS_ATTRIBUTE)
              gems = gems_attribute[:attribute_value] ||= []
              gems << BYEBUG_GEM unless gems.include?(BYEBUG_GEM)
            end
          end
        end

        private

        BREAKPOINT_TYPE_ATTRIBUTE = 'breakpoint_type'

        def self.breakpoint_class?(dynamic_provider)
          if breakpoint_type_attribute = matching_attribute?(BREAKPOINT_TYPE_ATTRIBUTE, dynamic_provider)
            if breakpoint_type = breakpoint_type_attribute[:attribute_value]
              BREAKPOINT_TYPE_TO_CLASS[breakpoint_type] || fail(ErrorUsage,"Illegal breakpoint type '#{breakpoint_type}'")
            end
          else
            LEGACY_PROVIDER_TYPE_TO_BREAKPOINT_CLASS[dynamic_provider.type]
          end
        end
          
        BREAKPOINT_TYPE_TO_CLASS = {
          'byebug'  => Byebug
        }

        LEGACY_PROVIDER_TYPE_TO_BREAKPOINT_CLASS = {
          'ruby' => Byebug 
        }

        def self.matching_attribute?(attribute_name, dynamic_provider)
          dynamic_provider.provider_attributes.find { |attribute| attribute.display_name == attribute_name }
        end
        
        def matching_attribute?(attribute_name)
          self.class.matching_attribute?(attribute_name, self.dynamic_provider)
        end

      end
    end
  end
end
