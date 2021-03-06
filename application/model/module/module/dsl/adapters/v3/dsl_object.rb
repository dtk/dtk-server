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
module DTK; class ModuleDSL; class V3
  DSLObjectBase = ModuleDSL::V2::DSLObject
  class DSLObject < DSLObjectBase
    class Module < DSLObjectBase::Module
      def set_include_modules!(ret, opts = {})
        ret.set_unless_nil('includes', opts[:include_modules])
      end
    end

    class Attribute < DSLObjectBase::Attribute
      def render_hash_form(_opts = {})
        ret = RenderHash.new
        ret.set_unless_nil('description', value(:description))
        ret['type'] = required_value(:type)
        ret['required'] = true if value(:required)
        ret.set_unless_nil('dynamic', converted_dynamic())
        ret.set_unless_nil('default', converted_default())
        ret.set_unless_nil('external_ref', converted_external_ref())
        ret
      end

      private

      def converted_dynamic
        unless ScaffoldingStrategy[:no_dynamic_attributes]
          ret = value(:dynamic)
          if ret.nil? then (has_default_variable?() ? true : nil)
          else ret
          end
        end
      end

      def converted_default
        unless ScaffoldingStrategy[:no_defaults]
          if ret = value(:default_info)
            ret
          elsif has_default_variable?()
            ExtRefPuppetHeader
          end
        end
      end
      ExtRefPuppetHeader = 'external_ref(puppet_header)'

      def has_default_variable?
        unless ScaffoldingStrategy[:no_dynamic_attributes]
          !(value(:external_ref) || {})['default_variable'].nil?
        end
      end

      def converted_external_ref
        ret = RenderHash.new
        ext_ref = required_value(:external_ref)
        attr_name = ext_ref['name']
        unless attr_name == value(:id)
          ret[ext_ref['type']] = attr_name
        end
        # catchall: ignore proceesed keys and default_variable
        (ext_ref.keys - ['name', 'type', 'default_variable']).each { |k| ret[k] = ext_ref[k] }
        ret.empty? ? nil : ret
      end
    end
  end
end; end; end