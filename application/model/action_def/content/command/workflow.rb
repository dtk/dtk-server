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
    class Workflow < self

      attr_reader :subtasks_content

      def needs_template_substitution?
        @needs_template_substitution
      end

      def initialize(subtasks_content, additional_options = {})
        @subtasks_content            = subtasks_content
        @template_processor          = Content::TemplateProcessor.default
        @needs_template_substitution = ret_needs_template_substitution?()
      end

      def self.parse?(serialized_command)
        subtasks, subtasks_content = serialized_command
        new(subtasks_content) if subtasks_content
      end

      def bind_template_attributes!(attr_val_pairs)
        ret = []
        @subtasks_content.each do |subtask|
          subtask_str = subtask.to_yaml
          substitute_unparsed_values! subtask_str
          ret << YAML.load(@template_processor.bind_template_attributes(subtask_str, attr_val_pairs))
        end
        @subtasks_content = ret
        @needs_template_substitution = false
        self
      end

      def type
        'workflow'
      end

      private

      def ret_needs_template_substitution?
        @template_processor.needs_template_substitution?(@subtasks_content.to_s) 
      end

      def substitute_unparsed_values!(yaml_string)
        yaml_string.scan(/:{\"(\w*)\"=>nil}:/).flatten.each do |param|
          yaml_string.gsub!(/:{\"(#{Regexp.quote(param)})\"=>nil}:/, append_moustache(param))
        end
      end

      def append_moustache(param)
        '{{' + param + '}}'
      end

    end
  end
end; end; end