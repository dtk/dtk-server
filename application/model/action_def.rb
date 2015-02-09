module DTK
  class ActionDef < Model
    r8_nested_require('action_def','content')
    def self.common_columns()
      [:id,:display_name,:group_id,:method_name,:content,:component_component_id]
    end
  end
end
