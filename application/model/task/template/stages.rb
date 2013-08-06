module DTK; class Task 
  class Template
    class Stages 
      class Internode < Array
        def create_subtasks(task_mh,assembly_idh)
          ret = Array.new
          return ret if empty?()
          all_actions = Array.new
          each_with_index do |internode_stage,internode_stage_index|
            internode_stage_index = internode_stage_index+1
            internode_stage_task = Task.create_stub(task_mh,:display_name => "config_node_stage_#{internode_stage_index.to_s}", :temporal_order => "concurrent")
            all_actions += internode_stage.add_subtasks!(internode_stage_task,internode_stage_index)
          end
          attr_mh = task_mh.createMH(:attribute)
          Task::Action::ConfigNode.add_attributes!(attr_mh,all_actions)
          ret
        end

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
