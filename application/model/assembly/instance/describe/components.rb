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
    module Components
      def self.describe(service_instance, params, opts = {})
        assembly_instance = service_instance.copy_as_assembly_instance
        dsl_version       = service_instance.get_service_instance_branch.dsl_version

        # using params.first for component name because currently we only have one level for components
        components_content_input = CommonDSL::ObjectLogic::Assembly::Component.generate_content_input(assembly_instance, (params || []).first)
        top_level_content_input  = CommonDSL::ObjectLogic::ContentInputHash.new('components' => components_content_input)

        yaml_content = CommonDSL::Generate::FileGenerator.generate_yaml_text(:component, top_level_content_input, dsl_version)
        hash_content = YAML.load(yaml_content)

        hash_content['components'] || {}
      end
    end
  end
end; end
