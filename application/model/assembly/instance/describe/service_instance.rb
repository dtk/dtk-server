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
module DTK; class Assembly::Instance
  module Describe
    module ServiceInstance
      def self.describe(service_instance, params)
        service_instance_files = CommonDSL::Generate::ServiceInstance.generate_service_dsl_content(service_instance.copy_as_assembly_instance, service_instance.get_service_instance_branch)
        service_instance_file = service_instance_files.find { |file| file[:path] == CommonDSL::FileType::ServiceInstance::DSLFile::Top.canonical_path }
        service_instance_file[:content] ? YAML.load(service_instance_file[:content]) : {}
      end
    end
  end
end; end
