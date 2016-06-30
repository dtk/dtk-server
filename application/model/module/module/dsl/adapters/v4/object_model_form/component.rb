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
    class Component < OMFBase::Component
      private

      def body(input_hash, cmp, context = {})
        ret = OutputHash.new
        unless input_hash
          err_msg = "Missing definition for component '?1'"
          fail ParsingError.new(err_msg, component_print_form(cmp))
        end
        cmp_type = ret['display_name'] = ret['component_type'] = qualified_component(cmp)
        # version below refers to component brranch version not metafile version
        ret['version'] = ::DTK::Component.default_version()
        ret['basic_type'] = 'service'
        ret.set_if_not_nil('description', input_hash['description'])
        add_attributes!(ret, cmp_type, input_hash)
        opts = {}
        add_dependent_components!(ret, input_hash, cmp_type, opts)
        ret.set_if_not_nil('component_include_module', include_modules?(input_hash, cmp_type, context))
        if opts[:constants]
          add_attributes!(ret, cmp_type, ret_input_hash_with_constants(opts[:constants]), constant_attribute: true)
        end
        set_action_def_and_external_ref!(ret, input_hash, cmp, context)
        ret.set_if_not_nil('only_one_per_node', only_one_per_node(input_hash, ret['external_ref']))
        ret
      end

      def only_one_per_node(input_hash, external_ref)
        # if only_one_per_node is explicily or singleton are given then use this value
        ret = input_hash['only_one_per_node'] || input_hash['singleton']
        return ret unless ret.nil?
        
        # otherwise default is to make only_one_per_node true unless external_ref['type'] is set to 'puppet_definition'
        (external_ref || {})['type'] != 'puppet_definition'
      end

      def set_action_def_and_external_ref!(ret, input_hash, cmp, _context = {})
        create_action = nil
        function = nil
        docker = nil

        if action_def = ActionDef.new(cmp).convert_action_defs?(input_hash)
          if validate_action_def_function(action_def)
            function = action_def.delete_create_action!()
          elsif validate_action_def_docker(action_def)
            docker = action_def.delete_create_action!()
          else
            create_action = action_def.delete_create_action!()
          end
        end

        unless action_def.nil? || action_def.empty?
          ret['action_def'] = action_def
        end

        if function
          if ret['action_def']
            ret['action_def']['create'] = function
          else
            ret['action_def'] = { 'create' => function }
          end
        end

        if docker
          if ret['action_def']
            ret['action_def']['create'] = docker
          else
            ret['action_def'] = { 'create' => docker }
          end
        end

        # If ret['external_ref'] is nil that means to use the 'no_op' config adapter
        ret['external_ref'] =
          if input_hash['external_ref'] then external_ref(input_hash['external_ref'], cmp) # this is for legacy
          elsif create_action then external_ref_from_create_action?(create_action, cmp, ret)
          elsif function then external_ref_from_function?(function, cmp)
          elsif docker then external_ref_from_docker?(docker, cmp)
          end
        ret
      end

      def external_ref_from_create_action?(create_action, cmp, ret)
        if DTK::ActionDef::Constant.matches?(create_action[:method_name], :CreateActionName)
          if create_action[:content].respond_to?(:external_ref_from_create_action)
            external_ref(create_action[:content].external_ref_from_create_action(), cmp)
          elsif create_action[:content].respond_to?(:external_ref_from_bash_command)
            (ret['action_def'] ||= {}).merge!('create' => create_action)
            create_action[:content].external_ref_from_bash_command()
          end
        end
      end

      def external_ref_from_function?(function, _cmp)
        if DTK::ActionDef::Constant.matches?(function[:method_name], :CreateActionName)
          if function[:content].respond_to?(:external_ref_from_function)
            function[:content].external_ref_from_function()
          end
        end
      end

      def external_ref_from_docker?(docker, _cmp)
        if DTK::ActionDef::Constant.matches?(docker[:method_name], :CreateActionName)
          if docker[:content].respond_to?(:external_ref_from_docker)
            docker[:content].external_ref_from_docker()
          end
        end
      end

      def validate_action_def_function(action_def)
        if kv = DTK::ActionDef::Constant.matching_key_and_value?(action_def, :CreateActionName)
          create = kv.values.first
          create[:content] && create[:content].key?(:functions)
        end
      end

      def validate_action_def_docker(action_def)
        if kv = DTK::ActionDef::Constant.matching_key_and_value?(action_def, :CreateActionName)
          create = kv.values.first
          create[:content] && create[:content].key?(:docker)
        end
      end
    end
  end
end; end; end