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
  module CommonDSL
   module Parse
     require_relative('parse/file_obj')
     require_relative('parse/directory_parser')
     require_relative('parse/file_parser')
     require_relative('parse/canonical_input')

     def self.matching_common_module_file_obj?(module_branch)
       DirectoryParser.matching_file_obj?(FileType::CommonModule, branch: module_branch)
     end

     def self.matching_service_instance_file_obj?(module_branch)
       DirectoryParser.matching_file_obj?(FileType::ServiceInstance, branch: module_branch)
     end

     def self.set_dsl_version!(module_branch, parsed_common_module)
       module_branch.set_dsl_version!(parsed_common_module.req(:DSLVersion))
     end

   end
 end
end
