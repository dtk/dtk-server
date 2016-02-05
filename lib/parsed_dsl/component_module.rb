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
  module ParsedDSL
    class ComponentModule
      def initialize
        @module_dsl_obj = nil
      end

      def raw_hash
        raise_error_if_empty('raw_hash')
        @module_dsl_obj.raw_hash
      end

      def version_normalized_hash
        raise_error_if_empty('version_normalized_hash')
        @module_dsl_obj.version_normalized_hash
      end

      def add(module_dsl_obj)
        Log.error("Unexpected that @module_dsl_obj is already set") if @module_dsl_obj
        @module_dsl_obj = module_dsl_obj
      end

      def empty?
        @module_dsl_obj.nil?
      end

      private

      def raise_error_if_empty(method_name)
        fail Error, "The method '#{method_name}' should not be called when @module_dsl_obj is nil" unless @module_dsl_obj
      end
    end
  end
end