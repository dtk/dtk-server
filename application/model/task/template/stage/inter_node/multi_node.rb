module DTK; class Task; class Template; class Stage 
  class InterNode
    class MultiNode

      def self.parse_type(multi_node_type)
        case multi_node_type
          when "All_applicable" then Applicable
          else raise ParseError.new("Illegal multi node type (#{multi_node_type})")
        end
      end

      #This is used to include all applicable classes
      class Applicable < self
        def self.parse_and_reify(serialized_node_actions,action_list)
          info_per_node = Hash.new #indexed by node_id
          serialized_node_actions[:ordered_components].each do |cmp_ref|
            #TODO: if there is a title then we need to match on title
            cmp_type = cmp_ref
            matching_actions = action_list.select{|a|a.match_component_type?(cmp_type)}
            matching_actions.each do |a|
              node_id = a.node_id
              pntr = info_per_node[node_id] ||= {:actions => Array.new, :name => a.node_name, :id => node_id}
              pntr[:actions] << cmp_ref
            end
          end
          info_per_node.values.inject(Hash.new) do |h,n|
            h.merge(InterNode.parse_and_reify_node_actions({:ordered_components => n[:actions]},n[:name],n[:id],action_list))
          end
        end

      end
    end
  end
end; end; end; end


