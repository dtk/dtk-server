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
    ##
    # Makes ure node is on
    # when she moves from pending state to running state.
    ##
    # TODO: move common fns with CreateNode up and then have this inherit from common
    #       because there are things in create nodes not relaevant
    # TODO: class is minsomer it is more like 'make sure node is on'
    # TODO: DTK-2819; creation of this shoujdl be updated so that it takes an creation attribute that telles
    #       whether it is pwoer on or check state and then need an isnatnce version of task_display_name
    #       that looks at this; alternative can have two different tasks PowerOnNode and CheckNodeState
    class PowerOnNode < CreateNode
      def self.stage_display_name
        'ensure_nodes_are_running'
      end

      def self.task_display_name
        'ensure_node_is_running'
      end
    end
  end
end

