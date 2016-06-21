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
  module CommonModule::DSL
    module Parse
      require_relative('parse/directory')
      require_relative('parse/file')

      def self.update_model_from_dsl(module_branch)
        ret = ModuleDSLInfo.new
        file_obj = Directory.matching_file_obj?(::DTK::DSL::FileType::CommonModule, branch: module_branch)
        pp [:debug, 'CommonModule::DSL.update_model_from_dsl', :file_obj, file_obj]
        # TODO: now we run file parser
        ret
      end

    end
  end
end


      # TODO: Aldin - continue with update_from_clone and probably refactor
      # DTK-2445: Aldin:
      # Need to define a new parse_template_type that will do a full parse
      # we can start with full parse of just teh service module part and test with
      # project repo that just has service part
      # The call to parse wil be
      # parsed_output = DSL::FileParser.parse_content(:service_info, file_obj)
      # see https://github.com/dtk/dtk-dsl/blob/master/lib/dsl/file_parser.rb#L30
      # What neds to be passed in here is a file_obj
      # see https://github.com/dtk/dtk-dsl/blob/master/lib/dsl/util/file_obj.rb
      # to populate this the intent is to use
      # DTK::DSL::DirectoryParser
      # https://github.com/dtk/dtk-dsl/blob/master/lib/dsl/directory_parser/git.rb
      # which we would cut and paste from
      # https://github.com/dtk/dtk-common/blob/master/lib/dsl/directory_parser/git.rb
      # but for time being we could just directly use methods from
      # application/model/module/dsl_parser.rb
