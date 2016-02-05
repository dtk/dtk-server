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
  class NodeImage < Model
    def self.find_iaas_match(target, logical_image_name)
      legacy_bridge_to_node_template(target, logical_image_name)
    end

    private

    def self.legacy_bridge_to_node_template(target, logical_image_name)
      image_id, os_type = Node::Template.find_image_id_and_os_type(logical_image_name, target)
      image_id
    end
  end
end