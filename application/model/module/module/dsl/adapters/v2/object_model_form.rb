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
# TODO: this does some conversion of form; should determine what shoudl be done here versus subsequent parser phase
# TODO: does not check for extra attributes
module DTK; class ModuleDSL; class V2
  class ObjectModelForm < ModuleDSL::ObjectModelForm
    require_relative('object_model_form/component_choice_mixin') # this most go first
    require_relative('object_model_form/attribute_fields')
    require_relative('object_model_form/component')
    require_relative('object_model_form/choice')

    # :dependent_modules - if not nil then array of strings that are depenedent module
    def self.convert(input_hash, opts = {})
      new.convert(input_hash, opts)
    end
    def convert(input_hash, opts = {})
      component.new(input_hash.req(:module)).convert(input_hash['components'], context(input_hash, opts))
    end
    
    def self.convert_attribute_mapping(input_am, base_cmp, dep_cmp, opts = {})
      choice.new.convert_attribute_mapping(input_am, base_cmp, dep_cmp, opts)
    end

    private

    # can be overwritten
    def context(_input_hash)
      {}
    end
    def component
      self.class::Component
    end

    def choice
      self.class::Choice
    end
    
    def self.attribute_fields(attr_name, attr_info, opts = {})
      self::AttributeFields.convert(self, attr_name, attr_info, opts)
    end
    
    def attribute_fields(attr_name, attr_info, opts = {})
      self.class.attribute_fields(attr_name, attr_info, opts)
    end
    
    # returns a subset or hash for all keys listed; if an extyra keys then null signifying error condition is returned
    # '*' means required
    # e.g., keys ["*module","version"]
    def hash_contains?(hash, keys)
      req_keys = keys.inject({}) { |h, r| h.merge(r.gsub(/^\*/, '') => (r =~ /^\*/) ? 1 : 0) }
      ret = {}
      hash.each do |k, v|
        return nil unless req_keys[k]
        req_keys[k] = 0
        ret.merge!(k => v)
      end
      # return nil if there is a required key not found
      unless req_keys.values.find { |x| x == 1 }
        ret
      end
    end
  end
end; end; end
