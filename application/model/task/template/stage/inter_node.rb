module DTK; class Task; class Template
  class Stage 
    class InterNode < Hash
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
      
      def serialization_form()
        ret = Hash.new
        ret[:name] = @name if @name
        node_info = map_node_actions do |node_actions|
          node_name = node_actions.node_name()
          el = (node_name ? {:node  => node_name} : Hash.new).merge(:temporal_order => "concurrent")
          el.merge(:ordered_components => node_actions.serialization_form())
        end
        ret.merge(Serialization::Field::Subtasks => node_info)
      end
      
      def each_node_id(&block)
        each_key{|node_id|block.call(node_id)}
      end

      private

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

