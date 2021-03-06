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
module DTK; class Task; class Template
  class ActionList < ::Array
    r8_nested_require('action_list', 'config_components')

    def initialize(action_list = nil)
      super()
      @action_index = {}
      if action_list
        action_list.each do |a|
          unless i =  a.index
            fail Error.new('An action list passed into ActionList.new must have actions with set indexes')
          end
          @action_index[i] = a
          self << a
        end
      end
    end

    # sets @action_index on self and sets index on action if not set already
    # assumes that no indexs on action set or all or them, cannot be a mixture of these two cases
    def set_action_indexes!
      each_with_index do |a, i|
        a.index ||= i
        @action_index[a.index] = a
      end
      self
    end

    def index(i)
      @action_index[i]
    end

    def find_matching_node_id(node_name)
      # there can be multiple matches, but first match is fine since they will all agree on node_id
      if match = find_matching_action(node_name)
        unless node_id = match.node_id()
          Log.error("Unexpected that node id is nil for node name (#{node_name})")
        end
        node_id
      end
    end

    def find_matching_action(node_name, opts = {})
      find { |a| a.match?(node_name, opts[:component_name_ref]) }
    end

    def select(&block)
      ret = self.class.new()
      each { |el| ret << el if block.call(el) }
      ret.set_action_indexes!()
    end

    def <<(el)
      super(el.is_a?(Action) ? el : Action.create(el))
    end
  end
end; end; end