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

        def self.error__missing_component_or_action_key(serialized_el, opts = {})
          all_legal = all_string_variations(:ComponentsOrActions).join(', ')
          msg = ''
          if stage = opts[:stage]
            msg << "In stage '#{stage}', missing "
          else
            msg << 'Missing '
          end
          msg << "a component or action field (one of: #{all_legal}) in ?1"
          ParsingError.new(msg, serialized_el)
        end
      end
    end
  end
end; end
