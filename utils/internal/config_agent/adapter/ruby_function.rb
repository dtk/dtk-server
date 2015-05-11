module DTK; class ConfigAgent; module Adapter
  class RubyFunction < ConfigAgent
    def execute(task_action)
      #TODO: stub
      # TODO: DTK-2037. Adlin 
      # This is where processing of ruby function should be done; using task_action object
      # to look up the action def and then executing against its paramters and setting the dynamic paramter
      pp task_action
      nil
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
