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
# TODO: this does some conversion of form; should determine what shoudl be done here versus subsequent parser phase
# TODO: does not check for extra attributes
module DTK; class ModuleDSL; class V2
  class ObjectModelForm
    module ComponentChoiceMixin
      def add_dependency!(ret, dep_cmp, base_cmp)
        ret[dep_cmp] ||= {
          'type'           => 'component',
          'search_pattern' => { ':filter' => [':eq', ':component_type', dep_cmp] },
          'description'    => "#{component_print_form(dep_cmp)} is required for #{component_print_form(base_cmp)}",
          'display_name'   => dep_cmp,
          'severity'       => 'warning'
        }
      end
      
      def component_order(input_hash)
        if after_cmps = input_hash['after']
          after_cmps.inject(ObjectModelForm::OutputHash.new) do |h, after_cmp|
            after_cmp_internal_form = convert_to_internal_cmp_form(after_cmp)
            el = { after_cmp_internal_form =>
              { 'after' => after_cmp_internal_form } }
            h.merge(el)
          end
        end
      end
    end
  end
end; end; end
