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
# TODO: needs cleanup including around mechanism to get object associated with ids
module Ramaze::Helper::Common
  module RequestParams
    def request_params(*params)
      return request.params if params.size == 0
      ret = params.map { |p| request.params[p.to_s] }
      ret.size == 1 ? ret.first : ret
    end

    def required_request_params(*params)
      null_params = []
      ret = params.map do |p|
        unless val = request.params[p.to_s]
          null_params << p
        else val
        end
      end
      raise_error_null_params?(*null_params)
      ret.size == 1 ? ret.first : ret
    end

    def request_param_id(param, model_class = nil, extra_context = nil)
      id_or_name = required_request_params(param)
      resolve_id_from_name_or_id(id_or_name, model_class, extra_context)
    end

    def request_param_id?(param, model_class = nil, extra_context = nil)
      request_param_id(param, model_class, extra_context) if request_params(param)
    end

    def params_hash(*params)
      ret = {}
      # return ret unless request_method_is_post?()
      return ret if params.size == 0
      params.inject({}) do |h, p|
        val = request.params[p.to_s]
        (val ? h.merge(p.to_sym => val) : h)
      end
    end

    def boolean_request_params(*params)
      boolean_form(request_params(*params))
    end

    def boolean_form(obj)
      if obj.kind_of?(Array)
        obj.map { |el| boolean_form(el) }
      elsif obj.nil?
        nil
      else 
        obj.is_a?(TrueClass) || (obj.is_a?(String) && obj == 'true')
      end
    end

    ###### TODO: deprecate below for above
    def ret_request_params(*args)
      request_params(*args)
    end

    def ret_non_null_request_params(*args)
      required_request_params(*args)
    end

    def ret_request_param_id(*args)
      request_param_id(*args)
    end

    def ret_request_param_id_optional(*args)
      request_param_id?(*args)
    end

    def ret_params_hash(*args)
      params_hash(*args)
    end

    def ret_request_param_boolean(*args)
      boolean_request_params(*args)
    end
  end
end
