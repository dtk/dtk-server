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
  class CommandAndControl
    class IAAS < self

      # Can be overwritten
      def associate_persistent_dns?(_node)
      end

      # This should be overwritten
      def get_and_update_node_state!(_node, _attribute_names)
        fail Error.new("The method '#{self.class}#get_and_update_node_state' should be defined")
      end

      def self.node_print_form(node)
        "#{node[:display_name]} (#{node[:id]})"
      end

      def return_status_ok
        self.class.return_status_ok
      end
      def self.return_status_ok
        { status: 'succeeded' }
      end
    end
  end
end

