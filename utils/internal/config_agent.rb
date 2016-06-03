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
  class ConfigAgent
    r8_nested_require('config_agent', 'type')
    r8_nested_require('config_agent', 'adapter')
    r8_nested_require('config_agent', 'parse_error')
    r8_nested_require('config_agent', 'parse_errors_cache')

    def self.parse_given_module_directory(type, dir)
      load(type).parse_given_module_directory(dir)
    end
    def self.parse_given_filename(type, filename)
      load(type).parse_given_filename(filename)
    end
    def self.parse_given_file_content(type, file_path, file_content)
      load(type).parse_given_file_content(file_path, file_content)
    end

    def self.parse_provider_specific_dependencies?(type, impl_obj)
      processor = load(type)
      if processor.respond_to?(:parse_provider_specific_dependencies?)
        processor.parse_provider_specific_dependencies?(impl_obj)
      end
    end

    def self.load(type)
      Adapter.load(type)
    end

    def node_name(node)
      (node[:external_ref] || {})[:instance_id]
    end

    # This can be overwritten
    def interpret_error(error_in_result, _components)
      error_in_result
    end
  end
end
