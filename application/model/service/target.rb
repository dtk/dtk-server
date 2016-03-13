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
  class Service
    # Class for target service instances
    class Target < self
      r8_nested_require('target', 'node_template')
      include NodeTemplate

      def initialize(target_assembly_instance, target)
        @service_instance = target_assembly_instance
        @target = target
      end

      # This function is used toi help bridge between using targets and service insatnces
      # There are places in code where target is referenced, but we want to get a handle on a service isnatnce that has
      def self.create_from_target(target)
        # TODO: stub
        new(find_assembly_instance_from_target(target), target)
      end

      private

      def self.find_assembly_instance_from_target(target)
        # TODO: stub
      end

    end
  end
end
