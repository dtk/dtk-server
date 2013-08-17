module DTK; class Task
  class Template
    class Content < Array
      include Serialization
      def initialize(object,actions,opts={})
        super()
        create_stages!(object,actions,opts)
      end

      def create_subtask_instances(task_mh,assembly_idh)
        ret = Array.new
        return ret if empty?()
        all_actions = Array.new
        each_with_index do |internode_stage,stage_index|
          stage_index += 1
          task_hash = {
            :display_name => internode_stage.name || "config_node_stage#{size == 1 ? '' : ('_'+stage_index.to_s)}",
            :temporal_order => "concurrent"
          }
          internode_stage_task = Task.create_stub(task_mh,task_hash)
          all_actions += internode_stage.add_subtasks!(internode_stage_task,stage_index,assembly_idh)
          ret << internode_stage_task
        end
        attr_mh = task_mh.createMH(:attribute)
        Task::Action::ConfigNode.add_attributes!(attr_mh,all_actions)
        ret
      end

      def splice_in_at_beginning!(template_content)
        insert(0,*template_content)
        self
        #TODO: took at this deeper splicing; may deprecate
        #unless template_content.size == 1
        #  raise ErrorUsage.new("Can only splice in template content that has a single inter node stage")
        #end
        #first.splice_in_at_beginning!(template_content.first)
        #self  
      end
      
      def serialization_form(opts={})
        subtasks = map{|internode_stage|internode_stage.serialization_form(opts)}.compact
        if subtasks.empty?()
          raise Error.new("Not implemented: treatment of the task template with no actions")
        end
        #Dont put in sequential block if just single stage
        if subtasks.size == 1
          subtasks.first.delete(:name)
          subtasks.first
        else
          {
            Field::TemporalOrder => Constant::Sequential,
            Field::Subtasks => subtasks
          }
        end
      end
      def self.parse_and_reify(serialized_content,actions)
        #normalize to handle case wheer single stage; test fro single stage is whethet serialized_content[Field::TemporalOrder] == Constant::Sequential
        temporal_order = serialized_content[Field::TemporalOrder]
        has_multi_internode_stages = (temporal_order and (temporal_order.to_sym == Constant::Sequential))
        subtasks = serialized_content[Field::Subtasks]
        normalized_subtasks = 
          if subtasks
            has_multi_internode_stages ? subtasks : [{Field::Subtasks => subtasks}]
          else
            [serialized_content]
          end
        new(SerializedContentArray.new(normalized_subtasks),actions)
      end

      class SerializedContentArray < Array
        def initialize(array)
          super()
          array.each{|a|self << a}
        end
      end

    private        
      def create_stages!(object,actions,opts={})
        if object.kind_of?(TemporalConstraints)
          create_stages_from_temporal_constraints!(object,actions,opts)
        elsif object.kind_of?(SerializedContentArray)
          create_stages_from_serialzied_content!(object,actions,opts)
        else
          raise Error.new("create_stages! does not treat argument of type (#{object.class})")
        end
      end

      def create_stages_from_serialzied_content!(serialized_content_array,actions,opts={})
        serialized_content_array.each{|a| self <<  Stage::InterNode.parse_and_reify(a,actions)}
      end

      def create_stages_from_temporal_constraints!(temporal_constraints,actions,opts={})
        if opts[:node_centric_first_stage]
          node_centric_actions = actions.select{|a|a.source_type() == :node_group}
          create_stages_from_temporal_constraints_aux!(temporal_constraints, node_centric_actions,opts)
          assembly_actions = actions.select{|a|a.source_type() == :assembly}
          create_stages_from_temporal_constraints_aux!(temporal_constraints,assembly_actions,opts)
        else
          create_stages_from_temporal_constraints_aux!(temporal_constraints,actions,opts)
        end
      end

      def create_stages_from_temporal_constraints_aux!(temporal_constraints,actions,opts={})
        return if actions.empty?
        unless empty?()
          Log.error("stages have been created already; dynamically set stage_index")
        end
        inter_node_constraints = temporal_constraints.select{|r|r.inter_node?()}
        
        stage_factory = Stage::InterNode::Factory.new(actions,temporal_constraints)
        before_index_hash = inter_node_constraints.create_before_index_hash(actions)
        done = false
        stage_index = 0
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
            stage_index += 1
            name = (internode_stage_name_proc && internode_stage_name_proc.call(stage_index))
            self << stage_factory.create(stage_action_indexes,name)
          end
        end
      end

    end
  end
end; end
