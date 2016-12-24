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
  class ActionDef
    class DynamicProvider
      def initialize(params_hash)
        @provider_module     = :ruby_provider # TODO: stub 
        @provider_parameters = ret_provider_parameters(params_hash)
      end
      private :initialize
      
      def self.matching_dynamic_provider?(component_template, method_name)
        # TODO: 2805 this gives facade that hides external refs
        return create_when_create_method(component_template) if method_name == 'create'
        if action_def = ActionDef.get_matching_action_def?(component_template, method_name)
          new(action_def.content) 
        end
      end
      
      private
      
      def self.create_when_create_method(component_template)
        new(component_template.get_field?(:external_ref))
      end
      
      def ret_provider_parameters(params_hash)
        params_hash.inject({}) { |h, (k, v)| k == :provider ? h : h.merge(k => v) }
      end
    end
  end
end
