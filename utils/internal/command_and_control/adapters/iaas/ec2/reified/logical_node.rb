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
    module Reified
      class LogicalNode < DTK::Service::Reified::Component
        # opts can have keys
        # :reified_target
        def initialize(dtk_node, opts = {})
          @dtk_node       = dtk_node
          @reified_target = opts[:reified_target] || Target.new(Service::Target.create_from_node(dtk_node))
          # These get set on demand
          @credentials = nil
        end

        def credentials
          @credentials ||= get_credentials
        end
        
        private

        def get_credentials
          vpcs = @reified_target.vpcs

          if vpcs.empty?
            fail ErrorUsage, "No VPCs are in the target service"
          elsif vpcs.size > 2
            # TODO: need to use link from node for his
            fail Error, "Not implemented: A target service with multiple VPCS"
          end

          vpcs.first.credentials
        end

      end
    end
  end
end


