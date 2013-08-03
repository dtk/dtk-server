module DTK; class Task; 
  class Template
    class ActionList < Array
      r8_nested_require('action_list','config_components')
      def set_action_indexes!()
        each_with_index{|r,i|r[:action_index] = i}
        self
      end
    end
  end
end; end
