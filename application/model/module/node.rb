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
#TODO: this wil undergoe big changes Jan 2015
module DTK
  class NodeModule < BaseModule
    def self.model_type
      :node_module
    end

    def self.component_type
      :puppet #hardwired
    end

    def component_type
      :puppet #hardwired
    end

    def self.module_specific_type(config_agent_type)
      config_agent_type
    end

    class DSLParser < DTK::ModuleDSLParser
      def self.module_type
        :node_module
      end
      def self.module_class
        ModuleDSL
      end
    end
  end
end