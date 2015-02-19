module DTK; class Task; class Template; class Stage 
  class InterNode
    class MultiNode < self
      def initialize(serialized_multinode_action)
        super(serialized_multinode_action[:name])
        unless @ordered_components = components_or_actions(serialized_multinode_action)
          all_legal = Constant.all_string_variations(*ComponantOrActionConstants).join(',')
          msg = "Missing Component or Action field (#{all_legal})"
          if name = serialized_multinode_action[:name]
            msg << " in stage '#{name}'"
          end
          raise ParsingError.new(msg)
        end
      end

      def serialization_form(opts={})
        if opts[:form] == :explicit_instances
          super
        else
          serialized_form_with_name().merge(:nodes => serialized_multi_node_type(),Constant::OrderedComponents => @ordered_components)
        end
      end

      def self.parse_and_reify(multi_node_type,serialized_multinode_action,action_list)
        klass(multi_node_type).new(serialized_multinode_action).parse_and_reify!(action_list)
      end

     private
      ComponantOrActionConstants = [:OrderedComponents,:Components,:Actions]
      def components_or_actions(serialized_el)
        if match = ComponantOrActionConstants.find{|k|Constant.matches?(serialized_el,k)}
          Constant.matches?(serialized_el,match)
        end
      end

      def self.klass(multi_node_type)
        if Constant.matches?(multi_node_type,:AllApplicable)
          Applicable
        else 
          raise ParsingError.new("Illegal multi node type (#{multi_node_type}); #{Constant.its_legal_values(:AllApplicable)}")
        end
      end

      # This is used to include all applicable classes
      class Applicable < self
        # action_list can be nil for just parsing
        def parse_and_reify!(action_list)
          ret = self
          return ret unless action_list
          info_per_node = Hash.new #indexed by node_id
          @ordered_components.each do |serialized_action|
            cmp_ref,method_name = Action::WithMethod.parse(serialized_action)
            cmp_type,cmp_title = [cmp_ref,nil]
            if cmp_ref =~ CmpRefWithTitleRegexp
              cmp_type,cmp_title = [$1,$2]
            end
            matching_actions = action_list.select{|a|a.match_component_ref?(cmp_type,cmp_title)}
            matching_actions.each do |a|
              node_id = a.node_id
              pntr = info_per_node[node_id] ||= {:actions => Array.new, :name => a.node_name, :id => node_id}
              pntr[:actions] << serialized_action
            end
          end
          info_per_node.each_value do |n|
            if node_actions = InterNode.parse_and_reify_node_actions?({Constant::OrderedComponents => n[:actions]},n[:name],n[:id],action_list) 
              merge!(node_actions)
            end
          end
          ret
        end
        CmpRefWithTitleRegexp = /(^[^\[]+)\[([^\]]+)\]$/

        def serialized_multi_node_type()
          "All_applicable"
        end

      end
    end
  end
end; end; end; end


