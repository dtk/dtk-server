module DTK; class Task; class Template; class Stage
  class InterNode
    class MultiNode < self
      def initialize(serialized_multinode_action)
        super(serialized_multinode_action[:name])
        unless @ordered_components = components_or_actions(serialized_multinode_action)
          all_legal = Constant.all_string_variations(:ComponentsOrActions).join(',')
          msg = "Missing Component or Action field (#{all_legal})"
          if name = serialized_multinode_action[:name]
            msg << " in stage '#{name}'"
          end
          fail ParsingError.new(msg)
        end
      end

      def serialization_form(opts = {})
        if opts[:form] == :explicit_instances
          super
        else
          serialized_form_with_name().merge(Constant::OrderedComponents => @ordered_components)
        end
      end

      # opts can have keys:
      #  :just_parse (Boolean)
      def self.parse_and_reify(multi_node_type, serialized_multinode_action, action_list, opts = {})
        klass(multi_node_type).new(serialized_multinode_action).parse_and_reify!(action_list, opts)
      end

      private

      def components_or_actions(serialized_el)
        if ret = Constant.matches?(serialized_el, :ComponentsOrActions)
          ret.kind_of?(Array) ? ret : [ret]
        end
      end

      def self.klass(multi_node_type)
        if Constant.matches?(multi_node_type, :AllApplicable)
          Applicable
        else
          fail ParsingError.new("Illegal multi node type (#{multi_node_type}); #{Constant.its_legal_values(:AllApplicable)}")
        end
      end

      # This is used to include all applicable classes
      class Applicable < self
        # opts can have keys:
        #  :just_parse (Boolean)
        def parse_and_reify!(action_list, opts ={})
          ret = self

          if action_list.nil?
            if opts[:just_parse]
              # This wil raise error if a parsing error
              @ordered_components.each { |serialized_action| Action::WithMethod.parse(serialized_action) }
            else
              Log.error("Unexpected that action_list.nil? while opts[:just_parse] is not true")
            end
            return ret
          end
            
          info_per_node = {} #indexed by node_id
          @ordered_components.each do |serialized_action|
            parsed      = Action::WithMethod.parse(serialized_action)
            cmp_ref     = parsed.component_name_ref
            cmp_type    = cmp_ref
            method_name = parsed.method_name
            params      = parsed.params

pp [:debug,'params=',params] if params

            cmp_title = nil
            if cmp_ref =~ CmpRefWithTitleRegexp
              cmp_type = Regexp.last_match(1)
              cmp_title = Regexp.last_match(2)
            end
            matching_actions = action_list.select { |a| a.match_component_ref?(cmp_type, cmp_title) }
            matching_actions.each do |a|
              node_id = a.node_id
              pntr = info_per_node[node_id] ||= { actions: [], name: a.node_name, id: node_id }
              pntr[:actions] << serialized_action
            end
          end
          info_per_node.each_value do |n|
            if node_actions = InterNode.parse_and_reify_node_actions?({ Constant::OrderedComponents => n[:actions] }, n[:name], n[:id], action_list)
              merge!(node_actions)
            end
          end
          ret
        end
        CmpRefWithTitleRegexp = /(^[^\[]+)\[([^\]]+)\]$/

      end
    end
  end
end; end; end; end
