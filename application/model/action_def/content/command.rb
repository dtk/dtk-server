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
    r8_nested_require('command', 'syscall')
    r8_nested_require('command', 'file_positioning')
    r8_nested_require('command', 'ruby_function')
    r8_nested_require('command', 'docker')
    r8_nested_require('command', 'workflow')

    def self.parse(serialized_command)
      Syscall.parse?(serialized_command) || FilePositioning.parse?(serialized_command) || RubyFunction.parse?(serialized_command) ||
        Docker.parse?(serialized_command) || Workflow.parse?(serialized_command) || fail(Error.new("Parse Error: #{serialized_command.inspect}")) # TODO: bring in dtk model parsing parse error class
    end

    def syscall?
      is_a?(Syscall)
    end

    def file_positioning?
      is_a?(FilePositioning)
    end
  end
end; end; end