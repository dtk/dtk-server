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
  class ServiceSetting < Model
    r8_nested_require('service_setting', 'array')
    r8_nested_require('service_setting', 'attribute_settings')
    r8_nested_require('service_setting', 'node_bindings')

    def self.common_columns
      [
       :id,
       :display_name,
       :group_id,
       :node_bindings,
       :attribute_settings
      ]
    end

    def bind_parameters!(hash_params)
      reify!()
      apply_to_field?(:attribute_settings) { |settings| settings.bind_parameters!(hash_params) }
    end

    def apply_setting(target, assembly)
      reify!()
      apply_to_field?(:attribute_settings) { |settings| settings.apply_settings(assembly) }
      apply_to_field?(:node_bindings) { |node_bindings| node_bindings.set_node_bindings(target, assembly) }
    end

    def reify!
      reify_field!(:attribute_settings, AttributeSettings)
      reify_field!(:node_bindings, NodeBindings)
    end

    private

    def apply_to_field?(field, &block)
      if content = self[field]
        block.call(content)
      end
    end

    def reify_field!(field, klass)
      if content = self[field]
        unless content.is_a?(klass)
          self[field] = klass.new(content)
        end
      end
    end
  end
end