module DTK; class Task; class Template
  class Stage 
    class InterNode < Hash
      include Serialization
      def initialize(name=nil)
        super()
        @name = name
      end

      #returns all actions generated
      def add_subtasks!(parent_task,internode_stage_index,assembly_idh=nil)
        ret = Array.new
        each_node_actions do |node_actions|
          if action = node_actions.add_subtask!(parent_task,internode_stage_index,assembly_idh)
            ret << action
          end
        end
        ret
      end
      
      def serialization_form(opts={})
        ret = Hash.new
        ret[:name] = @name if @name and !opts[:no_inter_node_satge_name]
        
        #Dont put in concurrent block if there is just one node
        if single_stage = single_inter_node_stage?()
          ret.merge(single_stage.serialization_form(opts))
        else
          ret[Field::TemporalOrder] = Constant::Concurrent
          ret.merge(Field::Subtasks => map_node_actions{|node_actions|node_actions.serialization_form(opts)})
        end
      end

      def each_node_id(&block)
        each_key{|node_id|block.call(node_id)}
      end

     private
      def single_inter_node_stage?()
        values.first if size() == 1
      end

      def each_node_actions(&block)
        each_value{|node_actions|block.call(node_actions)}
      end

      def map_node_actions(&block)
        values.map{|node_actions|block.call(node_actions)}
      end

      class Factory
        def initialize(action_list,temporal_constraints)
          @action_list = action_list
          @temporal_constraints = temporal_constraints
        end

        def create(stage_action_indexes,name=nil)
          #first break each state into unordered list per node
          ret = InterNode.new(name)
          stage_action_indexes.each do |index|
            action = @action_list[index]
            (ret[action.node_id] ||= IntraNode::Unordered.new()) << action
          end
          
          intra_node_proc = Stage::IntraNode::Processor.new(@temporal_constraints)
          ret.each_node_id{|node_id|ret[node_id] = intra_node_proc.process(ret[node_id])}
          ret
        end
      end
    end
  end
end; end; end

