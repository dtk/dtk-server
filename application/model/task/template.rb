module DTK; class Task
  class Template < Model
    r8_nested_require('template','content')
    r8_nested_require('template','temporal_constraint')
    r8_nested_require('template','temporal_constraints')
    r8_nested_require('template','action')
    r8_nested_require('template','action_list')
    r8_nested_require('template','stage')
    r8_nested_require('template','config_components')

   private
    def self.reify(serialized_content)
      raise Error.new("Templae.reify is not yet implemented")
    end

    module ActionType
      Create = "__create_action"
    end

    def self.get_serialized_content(mh,task_action,filter)
      sp_hash = {
        :cols => [:content],
        :filter => [:and,filter,[:eq,:task_action,task_action]]
      }
      (get_obj(mh,sp_hash)||{})[:content]
    end

  end
end; end
