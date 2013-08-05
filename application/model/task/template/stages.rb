module DTK; class Task 
  class Template
    class Stages 
      class Internode < Array
        r8_nested_require('stages','create_task')
        include CreateTaskMixin
        def self.create_stages(temporal_constraints,action_list)
          new(action_list).create_stages!(temporal_constraints)
        end
        
        def serialization_form()
          map{|stage|stage.serialization_form()}
        end
        
        def create_stages!(temporal_constraints)
          ret = self
          #outer loop creates inter node stages
          return ret if @action_list.empty?
          unless empty?()
            raise Error.new("internode_stages has been created already")
          end
          inter_node_constraints = temporal_constraints.select{|r|r.inter_node?()}
          
          stage_factory = Stage::InterNode::Factory.new(@action_list,temporal_constraints)
          before_index_hash = inter_node_constraints.create_before_index_hash(@action_list)
          done = false
          #before_index_hash gets destroyed in while loop
          while not done do
            if before_index_hash.empty?
              done = true
            else
              stage_action_indexes = before_index_hash.ret_and_remove_actions_not_after_any!()
              if stage_action_indexes.empty?()
                #TODO: see if any other way there can be loops
                raise ErrorUsage.new("Loop detected in temporal orders")
              end
              self << stage_factory.create(stage_action_indexes)
            end
          end
          ret
        end
        
        private
        def initialize(action_list)
          @action_list = action_list
        end
      end
    end
  end
end; end
