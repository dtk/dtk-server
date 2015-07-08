module DTK; class Task; class Template
  class TaskParams
    include MustacheTemplateMixin

    def initialize(task_params)
      @task_params = task_params
    end

    def self.bind_task_params(hash,task_params)
      new(task_params).substitute_vars(hash)
    end

    def substitute_vars(object)
      if object.is_a?(Array)
        ret = object.class.new
        object.each{|el|ret << substitute_vars(el)}
        ret
      elsif object.is_a?(Hash)
        object.inject(object.class.new){|h,(k,v)|h.merge(k => substitute_vars(v))}
      elsif object.is_a?(String)
        substitute_vars_in_string(object)
      else
        object
      end
    end

    private

    def substitute_vars_in_string(string)
      unless needs_template_substitution?(string)
        return string
      end

      begin
        bind_template_attributes_utility(string,@task_params)
       rescue MustacheTemplateError::MissingVar => e
        ident = 4
        err_msg = "The variable '#{e.missing_var}' in the following workflow term is not set:\n#{' '*ident}#{string}"
        raise ErrorUsage.new(err_msg)
       rescue MustacheTemplateError => e
        raise ErrorUsage.new("Unbound variable in the workflow: #{e.error_message}")
      end
    end
  end
end; end; end
