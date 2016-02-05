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
    class FilePositioning < self
      attr_reader :command_line, :owner, :mode

      def initialize(serialized_command)
        @raw_form           = serialized_command
        @command_line       = serialized_command
        @template_processor = Content::TemplateProcessor.default # TODO: changed when have multiple choices for template processors
        @is_template        = serialized_command[:template]
        @owner              = serialized_command[:owner]
        @mode               = serialized_command[:mode]
        @needs_template_substitution = !!@template_processor.needs_template_substitution?(serialized_command[:target]) || !!@template_processor.needs_template_substitution?(serialized_command[:source])
      end

      def needs_template_substitution?
        @needs_template_substitution
      end

      def template?
        @is_template
      end

      def self.parse?(serialized_command)
        new(serialized_command) if serialized_command.is_a?(Hash) && serialized_command.key?(:ADD)
      end

      def bind_template_attributes!(attr_val_pairs)
        if target = @command_line[:target]
          @command_line[:target] = @template_processor.bind_template_attributes(target, attr_val_pairs)
        end

        if source = @command_line[:source]
          @command_line[:source] = @template_processor.bind_template_attributes(source, attr_val_pairs)
        end

        @needs_template_substitution = false
        self
      end

      def get_and_parse_template_content(local_dir, attr_val_pairs)
        template_path = "#{local_dir}/#{@command_line[:source]}"
        fail Error, "Template file '#{template_path}' does not exist." unless File.exist?(template_path)

        file_content = File.open(template_path).read
        substitute = !!@template_processor.needs_template_substitution?(file_content)

        file_content = @template_processor.bind_template_attributes(file_content, attr_val_pairs) if substitute
        file_content
      end

      def type
        'file'
      end
    end
  end
end; end; end