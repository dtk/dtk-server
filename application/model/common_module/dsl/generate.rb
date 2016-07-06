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
    module Generate
      require_relative('generate/content_input')
      require_relative('generate/file_generator')
      
      def self.generate_service_instance_dsl(module_branch)
        # content_input is a dsl version independent canonical form that has all content needed to
        # generate the dsl file using syntax for version  module_branch.dsl_version
        content_input = ContentInput.generate_for_service_instance(module_branch)
        pp [:content_input, content_input.class, content_input]
#        FileGenerator.generate(:assembly, content_input, module_branch.dsl_version)
      end
    end
  end
end

