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

     # opts can have keys
     #  :impacted_files - array
     def self.matching_common_module_top_dsl_file_obj?(module_branch, opts = {})
       DirectoryParser.matching_file_obj?(FileType::CommonModule::DSLFile::Top, opts.merge(branch: module_branch))
     end

     # opts can have keys
     #  :impacted_files - array
     def self.matching_service_instance_top_dsl_file_obj?(module_branch, opts = {})
       DirectoryParser.matching_file_obj?(FileType::ServiceInstance::DSLFile::Top, opts.merge(branch: module_branch))
     end

     def self.set_dsl_version!(module_branch, parsed_common_module)
       module_branch.set_dsl_version!(parsed_common_module.req(:DSLVersion))
     end
     
     module NestedModule
       Info = Struct.new(:module_name, :impacted_files) 
       def self.matching_files_array(all_impacted_files)
         # Returns array of DTK::DSL::FileType::MatchingFiles
         FileType::MatchingFiles.matching_files_array(FileType::ServiceInstance::NestedModule, all_impacted_files).map do |dsl_matching_files_obj|
           Info.new(dsl_matching_files_obj.file_type_instance.module_name, dsl_matching_files_obj.file_paths)
         end
       end
     end
     
   end
 end
end
