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
          raise ErrorUsage.new("Need to write")
        end
      end
    end
  end
end; end; end; end


