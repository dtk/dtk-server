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
module DTK; class ConfigAgent; module Adapter; class Puppet
  class ParseStructure
    class ParseError < ConfigAgent::ParseError
      def initialize(msg, opts = Opts.new)
        opts_parent = Opts.new
        if ast_item = opts[:ast_item]
          if line_num = ast_item.line
            opts_parent.merge!(line_num: line_num)
          end
        end
        super(msg, opts_parent)
      end
    end
  end
end; end; end; end