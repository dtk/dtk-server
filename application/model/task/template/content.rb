module DTK; class Task
  class Template
    class Content < Array
      include Serialization
      def initialize(object,action_list,opts={})
        super()
        create_stages!(object,action_list,opts)
      end

      def create_subtask_instances(task_mh,assembly_idh)
        ret = Array.new
        return ret if empty?()
        all_actions = Array.new
        each_with_index do |internode_stage,internode_stage_index|
          internode_stage_index = internode_stage_index+1
          #TODO: if only one node then dont need the outside 'concurrent wrapper'
          internode_stage_task = Task.create_stub(task_mh,:display_name => "config_node_stage_#{internode_stage_index.to_s}", :temporal_order => "concurrent")
          all_actions += internode_stage.add_subtasks!(internode_stage_task,internode_stage_index,assembly_idh)
          ret << internode_stage_task
        end
        attr_mh = task_mh.createMH(:attribute)
        Task::Action::ConfigNode.add_attributes!(attr_mh,all_actions)
        ret
      end
      
      def serialization_form()
        #Dont put in sequential block if just single stage
        if size == 1
          first.serialization_form(:no_inter_node_stage_name=>true)
        else
          subtasks = map{|internode_stage|internode_stage.serialization_form()}
          {
            Field::TemporalOrder => Constant::Sequential,
            Field::Subtasks => subtasks
          }
        end
      end
      def self.parse_and_reify(serialized_content,action_list)
        #normalize wrt whether there are explicit subtasks and then call create stages
        ret = new(SerializedContentArray.new(serialized_content[Field::Subtasks]||[serialized_content]),action_list)
        pp [:parse_and_reify,ret.serialization_form()]
        raise ErrorUsage.new("stop here")
        ret
      end

      class SerializedContentArray < Array
        def initialize(array)
          super()
          array.each{|a|self << a}
        end
      end

    private        
      def create_stages!(object,action_list,opts={})
        if object.kind_of?(TemporalConstraints)
          create_stages_from_temporal_constraints!(object,action_list,opts)
        elsif object.kind_of?(SerializedContentArray)
          create_stages_from_serialzied_content!(object,action_list,opts)
        else
          raise Error.new("create_stages! does not treat argument of type (#{object.class})")
        end
      end

      def create_stages_from_serialzied_content!(serialized_content_array,action_list,opts={})
        serialized_content_array.each{|a| self <<  Stage::InterNode.parse_and_reify(a,action_list)}
      end

      def create_stages_from_temporal_constraints!(temporal_constraints,action_list,opts={})
        return if action_list.empty?
        unless empty?()
          raise Error.new("stages have been created already")
        end
        inter_node_constraints = temporal_constraints.select{|r|r.inter_node?()}
        
        stage_factory = Stage::InterNode::Factory.new(action_list,temporal_constraints)
        before_index_hash = inter_node_constraints.create_before_index_hash(action_list)
        done = false
        internode_stage_index = 0
        internode_stage_name_proc = opts[:internode_stage_name_proc]

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
            internode_stage_index += 1
            name = (internode_stage_name_proc && internode_stage_name_proc.call(internode_stage_index))
            self << stage_factory.create(stage_action_indexes,name)
          end
        end
      end

    end
  end
end; end
