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
    # Wraps older objectsL Assembly::Instance and Target
    class Target < self
      r8_nested_require('target', 'node_template')
      include NodeTemplate

      def initialize(target_assembly_instance, target = nil)
        @assembly_instance = target_assembly_instance
        @target = target || target_assembly_instance.get_target
      end
      private :initialize

      def self.create_from_node(node)
        create_from_target(node.get_target)
      end


      # Creates a Service::Target object if assembly_instance represents a target service instance
      def self.create_from_assembly_instance?(assembly_instance)
        new(assembly_instance) if isa_target_assembly_instance?(assembly_instance)
      end

      # This function is used to help bridge between using targets and service instances
      # There are places in code where target is referenced, but we want to get a handle on a service isnatnce that has
      def self.create_from_target(target)
        new(find_assembly_instance_from_target(target), target)
      end

      def target
        Log.error("Unexepcetd that @target is nil") unless @target
        @target
      end

      def display_name
        @assembly_instance.get_field?(:display_name)
      end


      def self.target_when_target_assembly_instance?(assembly)
        assembly.copy_as_assembly_instance.get_target() if isa_target_assembly_instance?(assembly)
      end

      private

      def self.isa_target_assembly_instance?(assembly_instance)
        if specific_type = assembly_instance.get_field?(:specific_type)
          specific_type.eql?('target')
        end
      end

      def self.find_assembly_instance_from_target(target)
        # Assumption taht target name and assembly instance that corresponds to target have the same name
        sp_hash = {
          cols: [:id, :group_id, :display_name],
          filter: [:and, 
                   [:eq, :datacenter_datacenter_id, target.id],
                   [:eq, :display_name, target.get_field?(:display_name)]]
        }
        unless ret = Assembly::Instance.get_obj(target.model_handle(:assembly_instance), sp_hash)
          Log.error("Unexpected that find_assembly_instance_from_target returns nil")
        end
        ret
      end
    end
  end
end
