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
module DTK; class ActionDef; class Content
  class Command
    class RubyFunction < self
      attr_reader :ruby_function

      def needs_template_substitution?
        @needs_template_substitution
      end

      def initialize(ruby_function)
        @ruby_function = ruby_function
      end

      def process_function_assign_attrs(attrs, dyn_attrs)
        @ruby_function.each_pair do |d_attr, fn|
          begin
            evaluated_fn = proc do
              $SAFE = 1
              eval(fn)
            end.call

            unless attr_id  = (attrs.find { |a| a[:display_name].eql?(d_attr.to_s) } || {})[:id]
              return { error: ErrorUsage.new("lambda function output var '#{d_attr}' is not declared as a component attribute") }
            end
            attr_val = calculate_dyn_attr_value(evaluated_fn, attrs)
            dyn_attrs << { attribute_id: attr_id, attribute_val: attr_val }
          rescue SyntaxError => syntax_error
            fail SyntaxErrorParsing.error(d_attr, syntax_error)
          rescue SecurityError => e
            pp [e, e.backtrace[0..5]]
            return { error: e }
          end
        end
      end

      def self.parse?(serialized_command)
        if serialized_command.is_a?(Hash) && serialized_command.key?(:outputs)
          ruby_function = serialized_command[:outputs]
          new(ruby_function)
        end
      end

      def calculate_dyn_attr_value(evaluated_fn, attrs)
        value = nil
        parsed_attrs = parse_attributes(attrs)
        if evaluated_fn.is_a?(Proc) && evaluated_fn.lambda?
          params = process_lambda_params(evaluated_fn, parsed_attrs)
          value = evaluated_fn.call(*params)
        else
          fail Error.new('Currently only lambda functions are supported')
        end
        value
      end

      def process_lambda_params(lambda_fn, parsed_attrs)
        ret_params = []
        lambda_fn.parameters.each do |pm|
          ret_params << parsed_attrs[pm[1].to_s]
        end
        ret_params
      end

      def parse_attributes(attrs)
        parsed_attrs = {}
        attrs.each do |attr|
          if attr[:data_type].eql?('integer')
            parsed_attrs[attr[:display_name]] = (attr[:value_asserted] || attr[:value_derived]).to_i
          else
            parsed_attrs[attr[:display_name]] = attr[:value_asserted] || attr[:value_derived]
          end
        end
        parsed_attrs
      end

      def type
        'ruby_function'
      end

      module SyntaxErrorParsing
        def self.error(dynamic_attribute, syntax_error)
          error_msg = "Syntax error in inline ruby function to compute attribute '#{dynamic_attribute}'"
          if error_info = parse?(syntax_error.message)
            error_msg << " on line #{error_info.line_number}: #{error_info.message}"
          else
            error_msg << ": #{syntax_error.message}"
          end
          SyntaxError.new(error_msg)
        end

        private

        ParsedInfo = Struct.new(:line_number, :message)
        def self.parse?(err_msg)
          if err_msg =~ /^\(eval\):([0-9]+): syntax error, (.+$)/
            ParsedInfo.new($1, $2)
          end
        end

      end
    end
  end
end; end; end
