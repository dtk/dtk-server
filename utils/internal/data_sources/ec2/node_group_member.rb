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
module XYZ
  module DSNormalizer
    class Ec2
      class NodeGroupMember < Top
        definitions do
          target[:node_id] = foreign_key :node, source[:node_ref]
          target[:node_group_id] = foreign_key :node_group, source[:node_group_ref]
        end
        class << self
          def relative_distinguished_name(source)
            source[:ref]
          end
        end
      end
    end
  end
end