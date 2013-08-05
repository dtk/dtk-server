module DTK; class Task; class Template
  class ActionList < Array
    r8_nested_require('action_list','config_components')
    def set_action_indexes!()
      each_with_index{|a,i|a.index = i}
      self
    end

    def <<(el)
      super(Action.create(el))
    end
  end
end; end; end
