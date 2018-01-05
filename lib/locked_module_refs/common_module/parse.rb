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
module DTK
  class LockedModuleRefs::CommonModule
#    class Parse < self
    module Parse 
      def self.reify_content(mh, object, opts = {})
        return {} unless object
        # if Hash type then this comes from querying the model ref table
        if object.is_a?(::Hash)
          object.inject({}) do |h, (k, v)|
            if v.is_a?(ModuleRef)
              h.merge(k.to_sym => ModuleRef.reify(mh, v))
            else
              fail Error, "Unexpected value associated with component module ref: #{v.inspect}"
            end
          end
          #This comes from parsing the dsl file
        elsif object.is_a?(ServiceModule::DSLParser::Output) || object.is_a?(ComponentDSLForm::ModuleRefs)
          object.inject({}) do |h, r|
            internal_form = convert_parse_to_internal_form(r, opts)
            h.merge(parse_form_module_name(r).to_sym => ModuleRef.reify(mh, internal_form))
          end
        else
          fail Error, "Unexpected input '#{object.class}'"
        end
      end

      private

      def self.convert_parse_to_internal_form(parse_form_hash, opts = {})
        ret = {
          module_name: parse_form_hash[:component_module],
          module_type: 'component'
        }
        # TODO: should have dtk common return namespace_info instead of remote_namespace
        if namespace_info = parse_form_hash[:remote_namespace]
          ret[:namespace_info] = namespace_info
        end
        version_info = parse_form_hash[:version_info]
        if opts[:include_nil_version] or version_info
          ret[:version_info] = version_info
        end

        if external_ref = parse_form_hash[:external_ref]
          ret[:external_ref] = external_ref
        end

        ret
      end
    end
  end
end
