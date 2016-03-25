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
  class CommandAndControlAdapter::Ec2
    # For interpreting AWS target service instances
    class TargetServiceHelper
      r8_nested_require('target_service_helper', 'component')
      r8_nested_require('target_service_helper', 'violation')

      def initialize(node)
        @target_service = Service::Target.create_from_node(node)
      end

      def self.find_violations(target_service, cmps, project, params = {})
        Violation.find_violations(target_service, cmps, project, params)
      end

      def get_credentials(_node)
        # TODO: stub
        @target_service.target.get_aws_compute_params
      end
    end
  end
end

