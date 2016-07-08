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
  class CommonModule::Import::ServiceModule
    module Assembly
      module Components
        include ServiceDSLCommonMixin

        def self.db_update_hash(container_idh, components_hash, component_module_refs, opts = {})
          ret = {}
          return ret unless components_hash

          cmps_with_titles = []
          components_hash = [components_hash] unless components_hash.is_a?(Array)

          ret = components_hash.inject(DBUpdateHash.new) do |h, cmp_input|
            parse   = nil
            cmp_ref = nil

            parse = component_ref_parse(cmp_input)
            cmp_ref = Aux.hash_subset(parse, [:component_type, :version, :display_name])

            if cmp_ref[:version]
              cmp_ref[:has_override_version] = true
            end

            if cmp_title = parse[:component_title]
              cmps_with_titles << { cmp_ref: cmp_ref, cmp_title: cmp_title }
            end

            import_component_attribute_info(cmp_ref, cmp_input)

            h.merge(parse[:ref] => cmp_ref)
          end

          component_module_refs.set_matching_component_template_info?(ret.values, donot_set_component_templates: true, set_namespace: true)

          CommonModule::Import::ServiceModule.set_attribute_template_ids!(ret, container_idh)
          CommonModule::Import::ServiceModule.add_title_attribute_overrides!(cmps_with_titles, container_idh)

          ret
        end

        def self.component_ref_parse(cmp)
          cmp_type_ext_form  = (cmp.is_a?(Hash) ? cmp.keys.first : cmp)
          component_ref_info = InternalForm.component_ref_info(cmp_type_ext_form)

          type    = component_ref_info[:component_type]
          title   = component_ref_info[:title]
          version = component_ref_info[:version]

          ref          = ComponentRef.ref(type, title)
          display_name = ComponentRef.display_name(type, title)

          ret = { component_type: type, ref: ref, display_name: display_name }
          ret.merge!(version: version) if version
          ret.merge!(component_title: title) if title

          ret
        end

        def self.import_component_attribute_info(cmp_ref, cmp_input)
          ret_attribute_overrides(cmp_input).each_pair do |attr_name, attr_val|
            attr_overrides = import_attribute_overrides(attr_name, attr_val)
            update_component_attribute_info(cmp_ref, attr_overrides)
          end
        end

        def self.ret_component_hash(cmp_input)
          ret = {}
          if cmp_input.is_a?(Hash)
            ret = cmp_input.values.first
            unless ret.is_a?(Hash)
              err_msg = "Parsing error after component term (#{cmp_input.keys.first}) in: ?1"
              if ret.nil?
                err_msg << "\nThere is a nil value after this term"
              end
              fail ParsingError.new(err_msg, cmp_input)
            end
          end
          ret
        end

        def self.ret_attribute_overrides(cmp_input)
          ret_component_hash(cmp_input)['attributes'] || {}
        end

        def self.import_attribute_overrides(attr_name, attr_val, opts = {})
          attr_info = { display_name: attr_name, attribute_value: attr_val }
          if opts[:cannot_change]
            attr_info.merge!(cannot_change: true)
          end
          { attr_name => attr_info }
        end

        def self.output_component_attribute_info(cmp_ref)
          cmp_ref[:attribute_override] ||= {}
        end

        def self.update_component_attribute_info(cmp_ref, hash)
          output_component_attribute_info(cmp_ref).merge!(hash)
        end
      end
    end
  end
end
