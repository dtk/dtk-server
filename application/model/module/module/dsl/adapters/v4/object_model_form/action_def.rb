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
      require_relative('action_def/action_def_output_hash')
      require_relative('action_def/external_ref')

      module Constant
        module Variations
        end
        extend Aux::ParsingingHelper::ClassMixin

        ActionDefs = 'actions'
        Variations::ActionDefs = ['actions', 'action']

        # DTK-2805: for explicitly giving provider; may deprecate this
        Provider = 'provider'

        Parameters = 'parameters'
      end

      def initialize(component_name, opts = {})
        @component_name       = component_name
        @providers_input_hash = opts[:providers_input_hash]
      end
      private :initialize

      # opts can have keys:
      #   :providers_input_hash
      def self.set_action_info!(ret, input_hash, component_name, opts = {})
        new(component_name, opts).set_action_info!(ret, input_hash)
      end

      def set_action_info!(ret, input_hash)
        unless action_defs_input = Constant.matches?(input_hash, :ActionDefs)
          return ret
        end
        # action_def is for action def section has has info for multiple actions
        action_def_info = action_def_info(action_defs_input)

        set_action_def!(ret, action_def_info)

        # ExternalRef.external_ref? can update ret['action_def']
        # If ret['external_ref'] is nil that means to use the 'no_op' config adapter 
        ret['external_ref'] = ExternalRef.external_ref?(ret, @component_name, input_hash, action_def_info)

        ret
      end

      private

      # TODO: cleanup so dont need to partition into :non_create_actions, :create_action, :docker, :function
      ActionDefsInfo = Struct.new(:non_create_actions, :create_action, :docker, :function)
      #returns ActionDefInfo
      def action_def_info(action_defs_input)
        raise_error_ill_formed('actions section', action_defs_input) unless action_defs_input.is_a?(Hash)
        action_defs = action_defs_input.inject(ActionDefOutputHash.new) do |h, (action_name, action_body)|
          h.merge(convert_action_def(action_name, action_body))
        end

        function = docker = create_action = nil
        if has_action_def_type(:functions, action_defs)
          function = action_defs.delete_create_action!
        elsif has_action_def_type(:docker, action_defs)
          docker = action_defs.delete_create_action!
        else
          create_action = action_defs.delete_create_action!
        end
        ActionDefsInfo.new(action_defs, create_action, docker, function)
      end

      def set_action_def!(ret, action_def_info)
        unless action_def_info.non_create_actions.empty?
          ret['action_def'] = action_def_info.non_create_actions
        end
        if action_def_info.function
          (ret['action_def'] ||= {}).merge!('create' => action_def_info.function)
        end
        if action_def_info.docker
          (ret['action_def'] ||= {}).merge!('create' => action_def_info.docker)
        end
      end

      def convert_action_def(action_name, action_body)
        raise_error_if_illegal_action_name(action_name)
        action_body_hash = {
          method_name: action_name,
          display_name: action_name,
          content: Provider.create(action_body, providers_input_hash: @providers_input_hash, action_name: action_name, cmp_print_form: cmp_print_form)
        }
        if parameters = Parameters.create?(self, action_body, :action_name => action_name)
          action_body_hash.merge!('attribute' => parameters)
        end
        { action_name => OutputHash.new(action_body_hash) }
      end

      def has_action_def_type(type, action_defs)
        if kv = DTK::ActionDef::Constant.matching_key_and_value?(action_defs, :CreateActionName)
          create = kv.values.first
          create[:content] && create[:content].key?(type)
        end
      end

      def cmp_print_form
        component_print_form(@component_name)
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
