module DTK; class Task 
  class Template
    class Stage < Hash
      def self.create_with_unordered_intra_node_stages(stage_action_indexes,action_list)
        ret = new()
        stage_action_indexes.each do |index|
          node_id = action_list[index].node_id
          (ret[node_id] ||= IntraNode::Unordered.new) << index 
        end
        ret
      end
      
      def print_form(action_list)
        ret = Array.new
        return ret if empty?
        element_type = values.first.element_type()
        each do |node_id,node_action_indexes|
          ret << {element_type => node_action_indexes.map{|i|action_list[i].print_form()}}
        end
        ret
      end

      class IntraNode
        module CommonMixin
          def element_type()
            "IntraNode::#{self.class.to_s.split('::').last}"
          end
        end
        #although in an array, order does not make a difference
        class Unordered < Array
          include CommonMixin
        end
      end
    end
  end
end; end
