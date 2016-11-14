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
       # TODO: DTK-2707: replace this with semantic parse in dtk-dsl 
      module SyntaticTransform
        # returns [component_module_dsl_text, module_ref_text]; module_ref_text can be nil
        def self.transform(impacted_dsl_file)
          hash_content = hash_content(impacted_dsl_file)
          # TODO: get top keys 'dependent_modules' an d'components' and transform and convert to yaml
          # TODO: stub
          [' ', ' ']
        end
        
        # "dependent_modules"=>{"dtk/host"=>"master", "puppetlabs/stdlib"=>"4.3.1"},
        
        private
        
        def self.hash_content(impacted_file)
          # TODO: see if can avoid calling YamlHelper and instead call method on FileObj 
          file_obj = Parse::FileObj.new(Common.nested_module_top_dsl_file_type, impacted_file.path, content: impacted_file.content) 
          ::DTK::DSL::YamlHelper.parse(file_obj)
        end

      end
    end
  end
end; end
