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
module DTK; class Task; class Template; class Action
  class ComponentAction
    module InComponentGroupMixin
      def in_component_group(component_group_num)
        InComponentGroup.new(component_group_num, @component, self)
      end
      # overwritten by InComponentGroup
      def component_group_num
        nil
      end
    end
    class InComponentGroup < self
      attr_reader :component_group_num
      def initialize(component_group_num, component, parent_action)
        super(component, parent_action: parent_action)
        @component_group_num = component_group_num
      end
    end
  end
end; end; end; end