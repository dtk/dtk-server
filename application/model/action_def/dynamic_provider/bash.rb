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
  class ActionDef::DynamicProvider
    module Bash
      COMPONENT_NAME = 'bash'

      module Mixin
        def bash_script?
          unless @bash_script_is_set
            @bash_script = ret_bash_script?
            @bash_script_is_set = true
          end
          @bash_script
        end
        
        protected

        def ret_bash_script?
          if bash_script_template = self.bash_script_template? || Bash.legacy_bash_script_template_for_ruby_provider?(self.type)
            attribute_values = provider_attributes.inject({}) { |h, attr| h.merge(attr.display_name => attr[:attribute_value]) }
            MustacheTemplate.render(bash_script_template, attribute_values)
          end
        end

        def bash_script_template?
          self.provider_bash? && self.provider_bash?.bash_script_template?
        end
        
        def provider_bash?
          unless @provider_bash_is_set
            @provider_bash_is_set = true
            @provider_bash = ret_provider_bash?
          end
          @provider_bash
        end
          
        private  
        
        def ret_provider_bash?
          if bash_component_template = self.provider_component_module.get_matching_component_template?(Bash::COMPONENT_NAME) 
            Component::Domain::Provider::Bash.new(bash_component_template)
          end
        end
      end

      def self.legacy_bash_script_template_for_ruby_provider?(type)
        if type == ActionDef::DynamicProvider::RUBY_TYPE
        <<eos
#!/usr/bin/env bash

set -e

{{#gems}}
gem install {{.}} --no-ri --no-rdoc >/dev/null
{{/gems}}
eos
        end
      end

    end
  end
end
