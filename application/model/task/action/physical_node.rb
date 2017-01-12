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
  class Task::Action
    # TODO: This may no longer be needed
    class PhysicalNode < self
      def initialize(_type, hash, task_idh = nil)
        unless hash[:node].is_a?(Node)
          hash[:node] &&= Node.create_from_model_handle(hash[:node], task_idh.createMH(:node), subclass: true)
        end
        super(hash)
      end
      
      def self.create_from_physical_nodes(target, node)
        node[:datacenter] = target
        hash = {
          node: node,
          datacenter: target,
          user_object: CurrentSession.new.get_user_object()
        }
        
        InstallAgent.new(:hash, hash)
      end
      
      def self.create_smoketest_from_physical_nodes(target, node)
        node[:datacenter] = target
        hash = {
          node: node,
          datacenter: target,
          user_object: CurrentSession.new.get_user_object()
        }
        
        ExecuteSmoketest.new(:hash, hash)
      end
      
      # virtual gets overwritten
      # updates object and the tasks in the model
      def get_and_update_attributes!(_task)
        # raise "You need to implement 'get_and_update_attributes!' method for class #{self.class}"
      end
      
      # virtual gets overwritten
      def add_internal_guards!(_guards)
        # raise "You need to implement 'add_internal_guards!' method for class #{self.class}"
      end
    end
  end
end


