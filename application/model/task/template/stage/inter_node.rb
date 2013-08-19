module DTK; class Task; class Template
  class Stage 
    class InterNode < Hash
      r8_nested_require('inter_node','factory')
      r8_nested_require('inter_node','multi_node')
      include Serialization
      
      def initialize(name=nil)
        super()
        @name = name
        @multi_node = nil
      end
      attr_accessor :name

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

      def splice_in_at_beginning!(internode_stage)
        ndx_splice_in_node_ids = internode_stage.node_ids().inject(Hash.new){|h,node_id|h.merge(node_id => true)}
        each_node_id do |node_id|
          if matching = internode_stage[node_id]
            self[node_id].splice_in_at_beginning!(matching)
            ndx_splice_in_node_ids.delete(node_id)
          end
        end
        ndx_splice_in_node_ids.keys.each do |node_id|
          merge!(node_id => internode_stage[node_id])
        end
        self
      end

      def serialization_form(opts={})
        subtasks = map_node_actions{|node_actions|node_actions.serialization_form(opts)}.compact
        return nil if subtasks.empty?
        
        ret = OrderedHash.new
        ret[:name] = @name if @name
        
        #Dont put in concurrent block if there is just one node
        if subtasks.size == 1
          ret.merge(subtasks.first)
        else
          ret.merge(Field::TemporalOrder => Constant::Concurrent, Field::Subtasks => subtasks)
        end
      end
      def self.parse_and_reify(serialized_content,action_list)
        #content could be either a concurrent block with multiple nodes, or a single node
        normalized_content = serialized_content[Field::Subtasks]||[serialized_content]
        normalized_content.inject(new(serialized_content[:name])) do |h,serialized_node_actions|
          el = 
            if multi_node_type = serialized_node_actions[:nodes]
              @multi_node = MultiNode.parse_type(multi_node_type)
              @multi_node.parse_and_reify(serialized_node_actions,action_list)
            else
              unless node_name = serialized_node_actions[:node]
                raise ParseError.new("Missing node reference in (#{serialized_node_actions.inspect})")
              end
              unless node_id = action_list.find_matching_node_id(node_name)
                raise ParseError.new("Node ref (#{node_name}) cannot be resolved")
              end
              parse_and_reify_node_actions(serialized_node_actions,node_name,node_id,action_list)
            end
          h.merge(el)
        end
      end

      def each_node_id(&block)
        each_key{|node_id|block.call(node_id)}
      end
      def node_ids()
        keys()
      end

     private
      def self.parse_and_reify_node_actions(node_actions,node_name,node_id,action_list)
        {node_id => Stage::IntraNode::ExecutionBlocks.parse_and_reify(node_actions,node_name,action_list)}
      end

      def each_node_actions(&block)
        each_value{|node_actions|block.call(node_actions)}
      end

      def map_node_actions(&block)
        values.map{|node_actions|block.call(node_actions)}
      end
    end
  end
end; end; end

