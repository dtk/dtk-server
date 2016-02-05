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
module DTK; class AttributeLink
  class Function
    class VarEmbeddedInText < WithArgs
      def value(opts = {})
        val = nil
        var = output_value(opts)
        # alternative sematics is to treat nil like var with empty string
        return val if var.nil?
        text_parts = constants[:text_parts].dup
        val = text_parts.shift
        text_parts.each do |text_part|
          val << var
          val << text_part
        end
        val
      end
    end
  end
end; end