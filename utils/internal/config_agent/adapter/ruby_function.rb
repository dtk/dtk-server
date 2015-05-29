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
=begin
Here is teh example test components dsl:
module: dtk2307
dsl_version: 1.0.0
components:
  test1:
    attributes:
      int1:
        type: integer
        required: true
      int2:
        type: integer
        required: true
      sum:
        type: integer
        dynamic: true
    actions:
      create:
        function:
          type: ruby_function
          outputs:
            sum: |
              lambda do |int1,int2|
                input1 + input2
              end
=end

# Below is code that moved from ruote/participant/execute_on_node.rb

    # cmp_actions = action[:component_actions]
    
    # cmp_actions.each do |cmp_action|
    #   component = cmp_action[:component]
    #   ext_ref = component[:external_ref]
    #   ext_ref.each do |fn|
    #     output = fn[:outputs][:ensemble_info]
    #     require 'yaml'
    #     a = YAML.load(output)
    #     rez = eval(output)
    #     rez.call([], 10)
    #   end
    #   # l = lambda { 1+1 }
    #   # res = l.call
    #   # ap res
    # end
