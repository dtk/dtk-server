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
        # :dtk_base_node
        def initialize(dtk_node, opts = {})
          @dtk_node       = dtk_node
          @reified_target = opts[:reified_target] || Target.new(Service::Target.create_from_node(dtk_node))
          @dtk_base_node  = opts[:dtk_base_node]
          # These get set on demand
          @credentials = nil
        end
      end
    end
  end
end


