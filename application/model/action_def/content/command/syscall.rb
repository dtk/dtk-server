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
    class Syscall < self
      r8_nested_require('syscall', 'interpret_results')
      attr_reader :command_line, :if_condition, :unless_condition, :timeout

      def needs_template_substitution?
        @needs_template_substitution
      end

      def initialize(raw_form, command_line, additional_options = {})
        @raw_form           = raw_form
        @command_line       = command_line
        @template_processor = Content::TemplateProcessor.default # TODO: changed when have multiple choices for template processors
        @if_condition       = additional_options[:if]
        @unless_condition   = additional_options[:unless]
        @timeout            = additional_options[:timeout]
        @needs_template_substitution = ret_needs_template_substitution?()
      end

      def self.parse?(serialized_command)
        if serialized_command.is_a?(String) && serialized_command =~ Constant::Command::RunRegexp
          command_line = Regexp.last_match(1)
          new(serialized_command, command_line)
        elsif command_line = serialized_command.is_a?(Hash) && (serialized_command[:command] || serialized_command[:RUN])
          additional_options = {
            if: serialized_command[:if],
            unless: serialized_command[:unless],
            timeout: serialized_command[:timeout]
          }
          new(serialized_command, command_line, additional_options)
        end
      end

      def bind_template_attributes!(attr_val_pairs)
        @command_line = @template_processor.bind_template_attributes(@command_line, attr_val_pairs)
        @if_condition = @template_processor.bind_template_attributes(@if_condition, attr_val_pairs) if @if_condition
        @unless_condition = @template_processor.bind_template_attributes(@unless_condition, attr_val_pairs) if @unless_condition
        @needs_template_substitution = false
        self
      end

      def type
        'syscall'
      end

      private

      def ret_needs_template_substitution?
        !![@command_line, @if_condition, @unless_condition].find { |s| @template_processor.needs_template_substitution?(s) }
      end
    end
  end
end; end; end