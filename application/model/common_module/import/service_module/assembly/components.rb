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
        # not using this yet
        # def self.db_update_hash(parsed_components)
        #   parsed_attributes.inject(DBUpdateHash.new) do |h, parsed_attribute|
        #     attr_name    = parsed_attribute.req(:Name)
        #     attr_val     = parsed_attribute.val(:Value)
        #     attr_content = {
        #       'display_name'   => attr_name,
        #       'value_asserted' => attr_val,
        #       'data_type'      => Attribute::Datatype.datatype_from_ruby_object(attr_val)
        #     }
        #     h.merge(attr_name => attr_content)
        #   end
        # end

        def self.db_update_hash(container_idh, components_hash, component_module_refs, opts = {})
          ret = {}
          return ret unless components_hash

          cmps_with_titles = []
          components_hash = [components_hash] unless components_hash.is_a?(Array)

          ret = components_hash.inject(DBUpdateHash.new) do |h, cmp_input|
            parse   = nil
            cmp_ref = nil

            begin
              parse = component_ref_parse(cmp_input)
              cmp_ref = Aux.hash_subset(parse, [:component_type, :version, :display_name])
              if cmp_ref[:version]
                cmp_ref[:has_override_version] = true
              end
              if cmp_title = parse[:component_title]
                cmps_with_titles << { cmp_ref: cmp_ref, cmp_title: cmp_title }
              end

              import_component_attribute_info(cmp_ref, cmp_input)

             rescue ParsingError => e
              return ParsingError.new(e.to_s, opts_file_path(opts))
            end
            h.merge(parse[:ref] => cmp_ref)
          end

          opts_set_matching = { donot_set_component_templates: true, set_namespace: true }
          component_module_refs.set_matching_component_template_info?(ret.values, opts_set_matching)
          set_attribute_template_ids!(ret, container_idh)
          add_title_attribute_overrides!(cmps_with_titles, container_idh)
          ret
        end

        def self.component_ref_parse(cmp)
          cmp_type_ext_form = (cmp.is_a?(Hash) ? cmp.keys.first : cmp)
          component_ref_info = InternalForm.component_ref_info(cmp_type_ext_form)
          type = component_ref_info[:component_type]
          title = component_ref_info[:title]
          version = component_ref_info[:version]
          ref = ComponentRef.ref(type, title)
          display_name = ComponentRef.display_name(type, title)
          ret = { component_type: type, ref: ref, display_name: display_name }
          ret.merge!(version: version) if version
          ret.merge!(component_title: title) if title
          ret
        end
      end
    end
  end
end
