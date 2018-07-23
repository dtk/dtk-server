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
# TODO: this does some conversion of form; should determine what shoudl be done here versus subsequent parser phase
# TODO: does not check for extra attributes
module DTK; class ModuleDSL; class V2
  class ObjectModelForm::Choice
    class LinkAttributeRef
      def initialize(attr_ref)
        @attr_ref = attr_ref
      end
      private :initialize

      def self.convert_simple(attr_ref, dep_or_base, cmp, input_or_output)
        new(attr_ref).convert_simple(dep_or_base, cmp, input_or_output)
      end
      def convert_simple(dep_or_base, cmp, input_or_output)
        # Index processing first
        index = nil 
        if self.attr_ref =~ /(^[^\[]+)\[([^\]]+)\]$/
          @attr_ref = Regexp.last_match(1)
          index = Regexp.last_match(2)
        end
        ret = convert_simple_aux(dep_or_base, cmp, input_or_output)
        ret << ".#{index}" if index
        ret
      end
      
      def self.convert_base(attr_ref, base_cmp, dep_attr_ref, dep_cmp, input_or_output, opts = {})
        is_constant?(attr_ref, base_cmp, dep_attr_ref, dep_cmp, opts) || convert_simple(attr_ref, :base, base_cmp, input_or_output)
      end

      def self.is_constant?(attr_ref, base_cmp, dep_attr_ref, dep_cmp, opts = {})
        new(attr_ref).is_constant?(base_cmp, dep_attr_ref, dep_cmp, opts)
      end
      def is_constant?(base_cmp, dep_attr_ref, dep_cmp, opts = {})
        return nil if has_variable?

        datatype = :string
        const = nil
        if self.attr_ref =~ /^'(.+)'$/
          const = Regexp.last_match(1)
        elsif ['true', 'false'].include?(self.attr_ref)
          const = self.attr_ref
          datatype = :boolean
        elsif self.attr_ref =~ /^[0-9]+$/
          const = self.attr_ref
          datatype = :integer
        elsif sanitized_attr_ref = is_json_constant?
          const = sanitized_attr_ref
          datatype = :json
        end
        unless constant_assign = (const && Attribute::Constant.create?(const, dep_attr_ref, dep_cmp, datatype))
          raise_bad_attribute_ref_in_link_def
        end
        constants = opts[:constants] ||= []
        unless constant_assign.is_in?(constants)
          constants << constant_assign
        end
        "#{ObjectModelForm.convert_to_internal_cmp_form(base_cmp)}.#{constant_assign.attribute_name}"
      end

      protected

      attr_reader :attr_ref

      private

      def convert_simple_aux(dep_or_base, cmp, input_or_output)
        if self.attr_ref =~ /(^[^.]+)\.([^.]+$)/ 
          if input_or_output == :input
            raise_bad_attribute_ref_in_link_def
          end
          prefix = Regexp.last_match(1)
          attr = Regexp.last_match(2)
          case prefix
            when '$node' then (dep_or_base == :dep) ? 'remote_node' : 'local_node'
          else raise_bad_attribute_ref_in_link_def
          end + ".#{attr.gsub(/host_address$/, 'host_addresses_ipv4.0')}"
        else
          has_dollar_sign = has_variable?
          if (input_or_output == :input && has_dollar_sign) ||
              (input_or_output == :output && !has_dollar_sign)
            raise_bad_attribute_ref_in_link_def
          end
          var_name = attr_ref
          # if dollar sign is first character and not embedded string than strip of dollar sign
          if var_name =~ /^\$[^\{]/
            var_name = var_name.gsub(/^\$/, '')
          end
          "#{ObjectModelForm.convert_to_internal_cmp_form(cmp)}.#{var_name}"
        end
      end
      
      def has_variable?
        self.attr_ref =~ /\$/
      end

      def raise_bad_attribute_ref_in_link_def
        require 'byebug'; byebug
        fail ParsingError.new("Attribute reference '?1' in link_def is ill-formed", self.attr_ref)
      end

      # returns sanitized_attr_ref
      def is_json_constant?
        # TODO: this is just temp hack in how whether it is detected; providing fro using ' rather than " in constant
        if self.attr_ref =~ /[{]/
          self.attr_ref.gsub(/'/, "\"")
        end
      end
    end
  end
end; end; end
