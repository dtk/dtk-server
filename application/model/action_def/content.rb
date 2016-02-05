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
module DTK; class ActionDef
  # Top class for content classes which as hash part store raw form and then have
  # instance attributes for the parsed form
  class Content < Hash
    r8_nested_require('content', 'constant')
    r8_nested_require('content', 'command')
    r8_nested_require('content', 'template_processor')

    attr_reader :commands, :functions
    def initialize(hash_content)
      super()
      replace(hash_content)
    end
    def self.parse(hash)
      new(hash).parse_and_reify!
    end

    def parse_and_reify!
      @commands = (self[Constant::Commands] || []).map do |serialized_command|
        Command.parse(serialized_command)
      end
      @functions = (self[Constant::Functions] || []).map do |serialized_command|
        Command.parse(serialized_command)
      end
      self
    end
  end
end; end