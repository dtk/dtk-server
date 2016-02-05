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
module DTK; class Task
  class Template
    class ParsingError < ErrorUsage::Parsing
      def initialize(msg, *args_x)
        args = Params.add_opts(args_x, error_prefix: ErrorPrefix, caller_info: true)
        super(msg, *args)
      end
      ErrorPrefix = 'Workflow parsing error'

      class MissingComponentOrActionKey < self
        include Serialization

        def initialize(serialized_el, opts = {})
          all_legal = Constant.all_string_variations(:ComponentsOrActions).join(', ')
          msg = ''
          if stage = opts[:stage]
            msg << "In stage '#{stage}', missing "
          else
            msg << 'Missing '
          end
          msg << "a component or action field (one of: #{all_legal}) in ?1"
          super(msg, serialized_el)
        end
      end
    end
  end
end; end