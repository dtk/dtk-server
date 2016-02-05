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
module DTK; class Task
  class Template
    module Serialization
      module Constant
        module Variations
        end
        extend Aux::ParsingingHelper::ClassMixin
        
        ComponentGroup = :Component_group
        
        Concurrent = :concurrent
        Sequential = :sequential
        OrderedComponents = :ordered_components
        Components = :components
        
        ## TODO: above are in old form and should be deprecated once all refernces are replaced
        
        Actions = 'actions'
        Variations::Actions = %w(actions action)
        
        AllApplicable = 'All_applicable'
        Variations::AllApplicable = %w(All_applicable All All_Applicable AllApplicable)
        
        Node = 'node'
        Variations::Node = %w(node node_group)
        NodeGroup = 'node_group'
        
        Nodes = 'nodes'
        Variations::Nodes = ['nodes'] #TODO: dont think we need this because single variation
        
        Subtasks = 'subtasks'
        
        ComponentsOrActions = 'components'
        Variations::ComponentsOrActions = %w(components component ordered_components ordered_component actions action)
        
        TemporalOrder = 'subtask_order'
        
        ActionParams = 'params'
        Variations::ActionParams = ['params', 'parameters']
      end
    end
  end
end; end