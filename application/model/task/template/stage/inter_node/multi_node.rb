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
          if serialized_node_actions[:ordered_components].size == 1
            #TODO: if there is a title then we match on title
            cmp_type = serialized_node_actions[:ordered_components].first
            matching_actions = action_list.select{|a|a.match_component_type?(cmp_type)}
            matching_actions.inject(Hash.new) do |h,a|
              h.merge(InterNode.parse_and_reify_node_actions(serialized_node_actions,a.node_name,a.node_id,action_list))
            end
          else
            raise Error.new("Stub does not treat (#{serialized_node_actions[:ordered_components].inspect})")
          end
        end
      end
    end
  end
end; end; end; end


