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
  class ModuleDSLInfo < ::Hash
    def initialize(hash = {})
      super()
      replace(hash)
    end

    def aggregate!(module_dsl_info)
      fail Error, "Parameter has type '#{module_dsl_info.class}', not ModuleDSLInfo" unless module_dsl_info.kind_of?(ModuleDSLInfo)
      merge!(module_dsl_info)
    end

    def dsl_parse_error=(dsl_parse_error)
      self[:dsl_parse_error] = dsl_parse_error
    end
    def dsl_parse_error?
      self[:dsl_parse_error]
    end

    def dsl_created_info=(dsl_created_info)
      self[:dsl_created_info] = dsl_created_info
    end

    def dsl_updated_info=(dsl_updated_info)
      self[:dsl_updated_info] = dsl_updated_info
    end

    def component_module_refs=(component_module_refs)
      self[:component_module_refs] = component_module_refs
    end

    def parsed_dsl
      raise_error_if_unset(:parsed_dsl)
      self[:parsed_dsl]
    end
    def set_parsed_dsl?(parsed_dsl)
      self[:parsed_dsl] = parsed_dsl if parsed_dsl
    end

    def set_external_dependencies?(ext_deps)
      self[:external_dependencies] ||= ext_deps if ext_deps
    end

    def hash_subset(*keys)
      Aux.hash_subset(self, keys)
    end

    private

    def raise_error_if_unset(key)
      fail Error.new("Accessor '#{key}' should not be called when it is unset") unless has_key?(key)
    end
    
    class Info < Hash
      def initialize(hash = {})
        raise_error_if_illegal_keys(hash.keys)
        super()
        replace(hash)
      end

      def merge(hash)
        raise_error_if_illegal_keys(hash.keys)
        super(hash)
      end

      def merge!(hash)
        raise_error_if_illegal_keys(hash.keys)
        super(hash)
      end

      private

      def raise_error_if_illegal_keys(keys)
        illegal_keys = keys - legal_keys
        unless illegal_keys.empty?
          fail Error.new("Illegal keys (#{illegal_keys.join(',')})")
        end
      end
    end

    # has info about a DSL file that is being generated
    class CreatedInfo < Info
      private

      def legal_keys
        [:path, :content, :hash_content]
      end
    end
    # has info about a DSL file that is being updated
    class UpdatedInfo < Info
      private

      def legal_keys
        [:msg, :commit_sha]
      end
    end
  end
end
