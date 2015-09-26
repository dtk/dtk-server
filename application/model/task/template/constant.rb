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
