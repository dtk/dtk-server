module DTK; class Task; class Template; class Stage 
  class InterNode
    class MultiNode < self
      def initialize(serialized_multinode_action)
        super(serialized_multinode_action[:name])
        @ordered_components = serialized_multinode_action[:ordered_components]
      end

      def serialization_form(opts={})
        if opts[:form] == :explicit_instances
          super
        else
          serialized_form_with_name().merge(:nodes => serialized_multi_node_type(),:ordered_components => @ordered_components)
        end
      end

      def self.parse_and_reify(multi_node_type,serialized_multinode_action,action_list)
        klass(multi_node_type).new(serialized_multinode_action).parse_and_reify!(action_list)
      end

     private
      def self.klass(multi_node_type)
        case multi_node_type
          when "All_applicable" then Applicable
          else raise ParseError.new("Illegal multi node type (#{multi_node_type})")
        end
      end

      #This is used to include all applicable classes
      class Applicable < self
        #action_list can be nil for just parsing
        def parse_and_reify!(action_list)
          ret = self
          return ret unless action_list
          info_per_node = Hash.new #indexed by node_id
          @ordered_components.each do |cmp_ref|
            #TODO: if there is a title then we need to match on title
            cmp_type = cmp_ref
            matching_actions = action_list.select{|a|a.match_component_type?(cmp_type)}
            matching_actions.each do |a|
              node_id = a.node_id
              pntr = info_per_node[node_id] ||= {:actions => Array.new, :name => a.node_name, :id => node_id}
              pntr[:actions] << cmp_ref
            end
          end
          info_per_node.each_value do |n|
            merge!(InterNode.parse_and_reify_node_actions({:ordered_components => n[:actions]},n[:name],n[:id],action_list))
          end
          ret
        end

        def serialized_multi_node_type()
          "All_applicable"
        end

      end
    end
  end
end; end; end; end


