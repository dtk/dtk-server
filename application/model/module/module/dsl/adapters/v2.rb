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
  class ModuleDSL
    class V2 < self
      r8_nested_require('v2', 'parser')
      r8_nested_require('v2', 'dsl_object')
      r8_nested_require('v2', 'object_model_form')
      r8_nested_require('v2', 'incremental_generator')
      def self.normalize(input_hash)
        object_model_form.convert(object_model_form::InputHash.new(input_hash))
      end

      def self.convert_attribute_mapping_helper(input_am, base_cmp, dep_cmp, opts = {})
        object_model_form.convert_attribute_mapping(input_am, base_cmp, dep_cmp, opts)
      end

      private

      # 'self:: form' used below because for example v3 subclasses from v2 and it includes V3::ObjectModelForm
      def self.object_model_form
        self::ObjectModelForm
      end
    end
  end
end