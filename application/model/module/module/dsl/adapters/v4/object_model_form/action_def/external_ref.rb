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
  class ObjectModelForm::ActionDef
    module ExternalRef
      # can update ret['action_def']
      def self.external_ref?(ret, component_name, input_hash, action_defs_info)
        if input_hash['external_ref'] 
          external_ref_aux(input_hash['external_ref']) # this is for legacy
        else
          create_action?(ret, component_name, action_defs_info) || function?(action_defs_info) ||  docker?(action_defs_info)
        end
      end
      
      private
      
      def self.create_action?(ret, component_name, action_defs_info)
        if create_action = action_defs_info.create_action
          if is_method_name?(create_action[:method_name])
            if create_action[:content].respond_to?(:external_ref_from_create_action)
              external_ref_aux(create_action[:content].external_ref_from_create_action, component_name)
            elsif create_action[:content].respond_to?(:external_ref_from_bash_command)
              (ret['action_def'] ||= {}).merge!('create' => create_action)
              create_action[:content].external_ref_from_bash_command
            end
          end
        end
      end
      
      def self.function?(action_defs_info)
        if function = action_defs_info.function
          if is_method_name?(function[:method_name])
            if function[:content].respond_to?(:external_ref_from_function)
              function[:content].external_ref_from_function
            end
          end
        end
      end
      
      def self.docker?(action_defs_info)
        if docker = action_defs_info.docker
          if is_method_name?(docker[:method_name])
            if docker[:content].respond_to?(:external_ref_from_docker)
              docker[:content].external_ref_from_docker
            end
          end
        end
      end
      
      def self.is_method_name?(string)
        ::DTK::ActionDef::Constant.matches?(string, :CreateActionName)
      end
      
      def self.external_ref_aux(input_hash, component_name)
        raise_parsing_error(component_name, input_hash) unless input_hash.is_a?(Hash)
        # TODO: cleanup when port this to dtk-dsl
        # TODO: DTK-2805; deprecate use of external_ref and out this info under action_def
        return input_hash if input_hash['provider'] == 'generic'
        
        raise_parsing_error(component_name, input_hash) unless input_hash.size == 1
        
        type = input_hash.keys.first
          name_key =
          case type
          when 'puppet_class' then 'class_name'
          when 'puppet_definition' then 'definition_name'
          when 'serverspec_test' then 'test_name'
          else fail ParsingError.new('Component (?1) external_ref has illegal type (?2)', component_name, type)
          end
        name = input_hash.values.first
        ObjectModelForm::OutputHash.new('type' => type, name_key => name)
      end
      
      def self.raise_parsing_error(component_name, input_hash)
        fail ParsingError.new('Component (?1) external_ref is ill-formed (?2)', component_name, input_hash)
      end
      
    end
  end
end; end; end
