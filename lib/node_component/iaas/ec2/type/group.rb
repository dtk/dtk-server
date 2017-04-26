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
  class NodeComponent::IAAS::Ec2::Type
    class Group < self
      def generate_new_client_token?
        # generate if does not exists or there are new group members to create
        attribute_value?(:client_token).nil? or new_group_members_to_create?
      end

      private

      INSTANCE_ID_KEY = 'instance_id'
      def new_group_members_to_create?
        existing_instances = (attribute_value?(:instances) || []).reject { |instance| instance[INSTANCE_ID_KEY].nil? }
        existing_instances.size < cardinaility
      end

      def cardinaility
        string_value = attribute_value(:cardinality)
        string_value.to_i
      end
    end
  end
end      
