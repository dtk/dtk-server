module DTK; class ConfigAgent; module Adapter
  class RubyFunction < ConfigAgent
    def execute(task_action)
      cmps_action_defs, attrs, dynamic_attrs = [], [], []
      actions = task_action.component_actions()

      actions.each do |action|
        cmp          = action[:component]
        attrs        << action[:attributes]
        template_idh = cmp.id_handle(:id => cmp[:ancestor_id])
        cmps_action_defs  = ActionDef.get_ndx_action_defs([template_idh])
      end

      process_ruby_functions(cmps_action_defs, attrs, dynamic_attrs)
      results = {
        :statuscode => 0,
        :statusmsg  => 'OK',
        :data       => {:status => :succeeded, :dynamic_attributes => dynamic_attrs}
      }
    end

    private
    def process_ruby_functions(cmps_action_defs, attrs, dyn_attrs)
      functions = []
      action_defs = cmps_action_defs.values.flatten
      action_defs.each{|a_def| functions << a_def.functions()}

      functions.flatten.each do |fn|
        fn.process_function_assign_attrs(attrs.flatten, dyn_attrs)
      end
    end
  end
end; end; end