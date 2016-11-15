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
module DTK; module CommonDSL
  class ComponentModuleRepoSync
    class Transform::SyncBranch 
      module SyntaticTransform
        # returns [component_module_dsl_text, module_ref_text]
        def self.transform(impacted_dsl_file)
          hash_content = hash_content(impacted_dsl_file)
         [component_module_dsl_hash(hash_content), module_ref_hash(hash_content)].map { |hash| yaml_generate(hash) }
        end

        private
        
        def self.hash_content(impacted_file)
          file_obj = Parse::FileObj.new(Common.nested_module_top_dsl_file_type, impacted_file.path, content: impacted_file.content) 
          ::DTK::DSL::YamlHelper.parse(file_obj)
        end

        def self.yaml_generate(hash)
          ::DTK::DSL::YamlHelper.generate(hash)
        end

        DSL_MAPPING = {
          'dsl_version' => lambda { |dsl_version| dsl_version },
          'module'      => lambda { |mod| mod.split('/').last }, # first part is naemsapce
          'components'  => lambda { |components| components}
        }
        def self.component_module_dsl_hash(hash_content)
          DSL_MAPPING.inject({}) do |h, (key, func)| 
            source_value = hash_content[key]
            mapped_value = source_value && func.call(source_value)
            h.merge(key =>  mapped_value)
          end
        end

        def self.module_ref_hash(hash_content)
          dependencies = hash_content['dependent_modules']
          { 'component_modules' => dependencies && dependencies.inject({}) { |h, (dep, version)| h.merge(transform_dependency(dep, version)) } } 
        end

        # TODO: might use parse routine in dtk-dsl
        def self.transform_dependency(dep, version)
          namespace, mod = dep.split('/')
          mapped_dep_value = { 'namespace' => namespace }
          if version and version != 'master'
            mapped_dep_value.merge!('version' => version)
          end
          { mod => mapped_dep_value }
        end
        
      end
    end
  end
end; end
