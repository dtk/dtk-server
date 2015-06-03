module DTK; class ConfigAgent; module Adapter
  class RubyFunction < ConfigAgent
    def execute(task_action)
      cmps_action_defs, attrs, dynamic_attrs = [], [], []
      actions = task_action.component_actions()

      actions.each do |action|
        attrs            << action[:attributes]
        cmp              =  action[:component]
        template_idh     =  cmp.id_handle(:id => cmp[:ancestor_id])
        cmps_action_defs =  ActionDef.get_ndx_action_defs([template_idh])
      end

      rf_results = process_ruby_functions(cmps_action_defs, attrs, dynamic_attrs)
      results    = parse_ruby_fn_results(rf_results, dynamic_attrs)
    end

    private
    def process_ruby_functions(cmps_action_defs, attrs, dyn_attrs)
      functions, results = [], []

      action_defs = cmps_action_defs.values.flatten
      action_defs.each{|a_def| functions << a_def.functions()}

      functions.flatten.each do |fn|
        results << fn.process_function_assign_attrs(attrs.flatten, dyn_attrs)
      end

      results
    end

    def parse_ruby_fn_results(rf_results, dyn_attrs)
      errors = ""
      results = {
        :statuscode => 0,
        :statusmsg  => 'OK',
        :data       => {:status => :succeeded, :dynamic_attributes => dyn_attrs}
      }
      res_with_errors = rf_results.select{|r| r.has_key?(:error)}
      return results if res_with_errors.empty?

      err_size = res_with_errors.size
      if err_size == 1
        errors = "#{res_with_errors.first[:error]}"
        ruby_fn_errors = 'ruby function error'
      else
        res_with_errors.each do |error|
          errors << "\n\t#{error[:error]}"
        end
        ruby_fn_errors = 'ruby function errors'
      end

      results.merge!({:statuscode => 1, :statusmsg => errors, :error_type => ruby_fn_errors})
      results
    end
  end
end; end; end
