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
  class TemplateProcessor
    class MustacheTemplate < self
      def needs_template_substitution?(string)
        ::DTK::MustacheTemplate.needs_template_substitution?(string)
      end

      def bind_template_attributes(command_line, attr_val_pairs)
        ::DTK::MustacheTemplate.render(command_line, attr_val_pairs)
      rescue ::DTK::MustacheTemplate::Error::MissingVar => e
        ident = 4
        err_msg = "The mustache variable '#{e.missing_var}' in the following command is not set:\n#{' ' * ident}#{command_line}"
        raise ErrorUsage.new(err_msg)
      rescue ::DTK::MustacheTemplate::Error => e
        raise ErrorUsage.new("Template error in command (#{command_line}): #{e.error_message}")
      end
    end
  end
end; end; end
