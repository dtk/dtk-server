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
      DOMAIN_COMPONENT_NAME = 'bash'

      module Mixin
        def bash?
          if @bash_set
            @bash
          else
            @bash_set = true
            #if bash_template = (@container_component && @container_component.dockerfile_template?) 
            bash_template = <<eos
#!/usr/bin/env bash

set -e

{{#gems}}
gem install {{.}} --no-ri --no-rdoc >/dev/null
{{/gems}}
eos
            attribute_values = provider_attributes.inject({}) { |h, attr| h.merge(attr.display_name => attr[:attribute_value]) } 
            @bash = MustacheTemplate.render(bash_template, attribute_values)
          end
        end
      end
      
    end
  end
end