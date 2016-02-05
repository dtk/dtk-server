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
module DTK; class ModuleDSL; class V4::ObjectModelForm
  class ActionDef
    class Parameters < self
      def self.create?(parent, input_hash, opts = {})
        ret = nil
        unless parameters = Constant.matches?(input_hash, :Parameters)
          return ret
        end
        ParsingError.raise_error_if_not(parameters, Hash)

        ret = parameters.inject(OutputHash.new) do |h, (attr_name, attr_info)|
          if attr_info.is_a?(Hash)
            h.merge(attr_name => attribute_fields(attr_name, attr_info))
          else
            fail ParsingError.new('Ill-formed parameter section for action (?1): ?2', 
                                  action_print_name(parent, opts), 
                                  'parameters' => parameters)
          end
        end
        ret.empty? ?  nil : ret
      end

      private

      def self.action_print_name(parent, opts = {}) 
        cmp_print_form = parent.cmp_print_form
        if action_name = opts[:action_name]
          "#{cmp_print_form}.#{action_name}"
        else
          "action on component #{cmp_print_form}"
        end
      end
    end
  end
end; end; end