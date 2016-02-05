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
# TODO: put this in def
module DTK; class Node
  class NodeAttribute
    class CanonicalName < String
      class PuppetVersion < self
        def initialize
          super('node_agent.puppet.version')
        end
      end
      class RootDeviceSize < self
        def initialize
          super('storage.root_device_size')
        end
      end
       Names =
          [
           'node_group.cardinality',
           'node_group.cardinality_max',
           'node_agent.puppet.version'

          ].map { |n| self.new(n) } +
        [PuppetVersion.new, RootDeviceSize.new]
    end
  end
end; end