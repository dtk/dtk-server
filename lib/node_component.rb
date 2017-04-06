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
  module NodeComponent
    require_relative('node_component/parsing')

    SUPPORTED_IAAS_TYPES = [:ec2]
    NODE_COMPONENT_COMPONENT = 'node'
    def self.node_component_type(iaas_type)
      "#{iaas_type}__#{NODE_COMPONENT_COMPONENT}"
    end

    def self.node_component_type_display_name(iaas_type)
      "#{iaas_type}::#{NODE_COMPONENT_COMPONENT}"
    end

    def self.node_component_ref(iaas_type, node_name)
      "#{node_component_type_display_name(iaas_type)}[#{node_name}]"
    end

    def self.component_types
      @component_types ||= SUPPORTED_IAAS_TYPES.map { |iaas_type| node_component_type(iaas_type) }
    end

  end
end
