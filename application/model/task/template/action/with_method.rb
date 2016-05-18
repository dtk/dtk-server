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
module DTK; class Task; class Template
  class Action
    # This represents an action with an explicit method, as opposed to other action terms, which just have component reference
    class WithMethod < self
      r8_nested_require('with_method', 'params')
      include Serialization

      # opts can have keys
      #  :params
      def initialize(action, action_def, opts = {})
        # @action = action
        @action = change_puppet_class_or_definition_for_delete(action, action_def)
        @method = ActionMethod.new(action_def)
        @params = opts[:params]
      end

      def change_puppet_class_or_definition_for_delete(action, action_def)
        # if delete action, use puppet class/definition from action_def
        if action_def[:method_name].eql?('delete')
          content = action_def.content
          external_ref = action.external_ref
          if (content[:provider]||'').eql?('puppet')
            class_or_definition = content[:puppet_class] || content[:puppet_definition]
            if external_ref[:definition_name]
              external_ref[:definition_name] = class_or_definition
            elsif external_ref[:class_name]
              external_ref[:class_name] = class_or_definition
            end
          end
        end

        action
      end

      def action_method?
        @method
      end

      def params?
        @params
      end

      def method_missing(name, *args, &block)
        @action.send(name, *args, &block)
      end

      def respond_to?(name)
        @action.respond_to?(name) || super
      end

      def is_no_op?
        !!ConfigAgent::Type.is_a?(config_agent_type, :no_op)
      end

      def config_agent_type
        if @method
          @method.config_agent_type
        else
          @action.config_agent_type
        end
      end

      ParseStruct = Struct.new(:component_name_ref,:method_name,:params)
      # returns ParseStruct
      #  method_name and params can be nil
      def self.parse(serialized_item, opts = {})
        unless ret = has_explicit_method?(serialized_item, opts)
          raise_action_ref_error(serialized_item) unless serialized_item.is_a?(String)
          ret = ParseStruct.new(serialized_item, nil, nil)
        end
        ret
      end

      def self.parse_component_name_ref(serialized_item)
        parse(serialized_item, just_component_name_ref: true).component_name_ref
      end

      private

      # returns ParseStruct if has explicit method otherwise returns nil
      # explicit form is
      #   component.method_name, or
      #   component[title].method_name
      # complication is that title can have a '.' in it
      def self.has_explicit_method?(serialized_item, opts = {})
        if serialized_item.is_a?(Hash)
          raise_action_ref_error(serialized_item) unless serialized_item.size == 1
          if params = hash_params_in_serialized_item?(serialized_item.values.first)
            opts = opts.merge(params: params)
          end
          serialized_item = serialized_item.keys.first.to_s
        elsif ! serialized_item.is_a?(String)
          raise_action_ref_error(serialized_item) 
        end
        has_explicit_method__with_title?(serialized_item, opts) || has_explicit_method__without_title?(serialized_item, opts)
      end

      def self.has_explicit_method__with_title?(serialized_item, opts = {})
        ret = nil
        cmp_with_title, rest = has_component_title?(serialized_item)
        return ret unless cmp_with_title
        if rest.empty?
          nil
        elsif rest =~ /^\.(.+$)/
          if opts[:just_component_name_ref]
            ParseStruct.new(cmp_with_title, nil, nil)
          else
            method_name, params = split_method_name_and_params(Regexp.last_match(1), opts)
            ParseStruct.new(cmp_with_title, method_name, params)
          end
        else
          raise_action_ref_error(serialized_item)
        end
      end

      def self.has_explicit_method__without_title?(serialized_item, opts = {})
        # first check to make sure that
        split = split_taking_into_account_title(serialized_item)
        case split.size
        when 1
          nil
        when 2
          component_name_ref = split[0]
          if opts[:just_component_name_ref]
            ParseStruct.new(component_name_ref, nil, nil)
          else
            method_name, params = split_method_name_and_params(split[1], opts)
            ParseStruct.new(component_name_ref, method_name, params)
          end
        else
          raise_action_ref_error(serialized_item)
        end
      end

      # if there is atitle returns [cmp_with_title, rest] where rest is everyting after the title and can be empty
      def self.has_component_title?(serialized_item)
        if serialized_item =~ /(^[^\[]+)\[([^\]]+)\](.*$)/
          cmp_with_title = "#{Regexp.last_match(1)}[#{Regexp.last_match(2)}]"
          rest = Regexp.last_match(3)
          [cmp_with_title, rest]
        end
      end

      def self.split_taking_into_account_title(serialized_item)
        # This provides for complication where there could be a '.' within title
        cmp_with_title, rest = has_component_title?(serialized_item)
        if cmp_with_title
          rest.empty? ? [cmp_with_title] : [cmp_with_title, rest.gsub(/^\./, '')]
        else
          serialized_item.split('.')
        end
      end

      # returns method_name, params
      # params can be nil
      # opts can have keys
      #  :params - params explicitly given in hash
      def self.split_method_name_and_params(serialized_item, opts = {})
        params_in_hash = opts[:params]
        params = method_name = nil
        if serialized_item =~ /(^[^ ]+)[ ]+(.+$)/
          method_name = Regexp.last_match(1)
          params      = Params.parse(Regexp.last_match(2))
          params.merge!(params_in_hash) if params_in_hash
        else
          method_name = serialized_item
          params      = (params_in_hash ? Params.new.merge(params_in_hash) : nil)
        end
        [method_name, params]
      end

      def self.hash_params_in_serialized_item?(serialized_item)
        if ret = Constant.matches?(serialized_item, :ActionParams)
          unless ret.kind_of?(Hash)
            fail ParsingError.new("The following action parameters term is ill-formed: ?1", serialized_item)
          end
          ret
        end
      end

      def self.raise_action_ref_error(serialized_item)
        fail ParsingError.new("The following action term is ill-formed: ?1", serialized_item)
      end
    end
  end
end; end; end