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
module DTK
  class ServiceModule; class AssemblyExport
    r8_require('v3')
    class V4 < V3
      r8_nested_require('v4', 'workflow_hash')

      def workflow_hash
        if task_template = assembly_hash()[:task_template]
          WorkflowHash.workflow_hash(task_template)
        end
      end

      def attr_overrides_output_form(non_def_attrs)
        ret = nil
        return ret unless non_def_attrs
        value_overrides = []
        attribute_info = []
        non_def_attrs.values.each do |attr|
          unless attr.is_title_attribute()
            value_overrides << { attr[:display_name] => attr_value_output_form(attr, :attribute_value) }
          end
          if base_tags = attr.base_tags?()
            attribute_info << { attr[:display_name] => attr_tags_setting(base_tags) }
          end
        end

        ret = attribute_info_ouput_form(:attributes, value_overrides).merge(
               attribute_info_ouput_form(:attribute_info, attribute_info))
        !ret.empty? && ret
      end

      def attr_tags_setting(tags)
        tags.size == 1 ? { tag: tags.first } : { tags: tags }
      end

      def attribute_info_ouput_form(key, array)
        if array.empty?
          {}
        else
          sorted = array.sort { |a, b| a.keys.first <=> b.keys.first }
          SimpleOrderedHash.new(key => SimpleOrderedHash.new(sorted))
        end
      end
    end
  end; end
end