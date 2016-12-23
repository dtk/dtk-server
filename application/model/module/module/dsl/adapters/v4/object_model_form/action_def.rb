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
module DTK; class ModuleDSL; class V4
  class ObjectModelForm
    class ActionDef < self
      require_relative('action_def/provider')
      require_relative('action_def/parameters')

      module Constant
        module Variations
        end
        extend Aux::ParsingingHelper::ClassMixin

        ActionDefs = 'actions'
        Variations::ActionDefs = ['actions', 'action']

        Provider = 'provider'

        Parameters = 'parameters'
      end

      def initialize(component_name)
        @component_name = component_name
      end

      class ActionDefOutputHash < OutputHash
        def has_create_action?
          DTK::ActionDef::Constant.matches?(self, :CreateActionName)
        end

        def delete_create_action!
          if kv = DTK::ActionDef::Constant.matching_key_and_value?(self, :CreateActionName)
            delete(kv.keys.first)
          end
        end
      end

      def convert_action_defs?(input_hash)
        ret = nil
        unless action_defs = Constant.matches?(input_hash, :ActionDefs)
          return ret
        end
        unless action_defs.is_a?(Hash)
          raise_error_ill_formed('actions section', action_defs)
        end
        action_defs.inject(ActionDefOutputHash.new) do |h, (action_name, action_body)|
          h.merge(convert_action_def(action_name, action_body))
        end
      end

      def cmp_print_form
        component_print_form(@component_name)
      end

      private

      def convert_action_def(action_name, action_body)
        raise_error_if_illegal_action_name(action_name)
        action_body_hash = {
          method_name: action_name,
          display_name: action_name,
          content: Provider.create(action_body, action_name: action_name, cmp_print_form: cmp_print_form)
        }
        if parameters = Parameters.create?(self, action_body, :action_name => action_name)
          action_body_hash.merge!('attribute' => parameters)
        end
        { action_name => OutputHash.new(action_body_hash) }
      end

      def raise_error_if_illegal_action_name(action_name)
        unless action_name =~ LegalActionNameRegex
          err_msg = "The action name '?1' on component '?2' has illegal characters"
          fail ParsingError.new(err_msg, action_name, cmp_print_form)
        end
      end
      LegalActionNameRegex = /^[a-zA-Z0-9_-]+$/

      def raise_error_ill_formed(section_type, obj)
        err_msg = "The following #{section_type} on component '?1' is ill-formed: ?2"
        fail ParsingError.new(err_msg, cmp_print_form, obj)
      end

    end
  end
end; end; end
