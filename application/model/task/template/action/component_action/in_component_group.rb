module DTK; class Task; class Template; class Action
  class ComponentAction
    module InComponentGroupMixin
      def in_component_group(component_group_num)
        InComponentGroup.new(component_group_num,@component,self)
      end
      # overwritten by InComponentGroup
      def component_group_num()
        nil
      end
    end
    class InComponentGroup < self
      attr_reader :component_group_num
      def initialize(component_group_num,component,parent_action)
        super(component,:parent_action => parent_action)
        @component_group_num = component_group_num
      end
    end
  end
end; end; end; end
