#
# Copyright (C) 2010-2016 dtk contributors
#
# This file is part of the dtk project.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
module DTK; class Task; class Template
  class TaskParams
    def initialize(task_params)
      @task_params = task_params
    end

    def self.bind_task_params(hash, task_params)
      new(task_params).substitute_vars(hash)
    end

    def substitute_vars(object)
      if object.is_a?(Array)
        ret = object.class.new
        object.each { |el| ret << substitute_vars(el) }
        ret
      elsif object.is_a?(Hash)
        object.inject(object.class.new) { |h, (k, v)| h.merge(k => substitute_vars(v)) }
      elsif object.is_a?(String)
        substitute_vars_in_string(object)
      else
        object
      end
    end

    private

    def substitute_vars_in_string(string)
      unless MustacheTemplate.needs_template_substitution?(string)
        return string
      end

      begin
        MustacheTemplate.render(string, @task_params)
       rescue MustacheTemplateError::MissingVar => e
        ident = 4
        err_msg = "The variable '#{e.missing_var}' in the following workflow term is not set:\n#{' ' * ident}#{string}"
        fail ErrorUsage.new(err_msg)
      end
    end
  end
end; end; end