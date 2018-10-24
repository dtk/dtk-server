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
    module Update
      module Mixin
        
        # returns true if an update made; this updates the ruby object
        # each element in the array input_module_refs
        # is a component module object with the added field :namespace_name
        def update_object_if_needed!(input_module_refs)
          ret  = false
          
          module_ref_diffs = get_module_ref_diffs(input_module_refs)
          
          if to_delete = module_ref_diffs[:delete]
            to_delete.each { |cmp_mod| delete_component_module_ref(cmp_mod[:display_name]) }
            ret = true
          end
          
          if to_add = module_ref_diffs[:add]
            to_add.each { |cmp_mod| add_or_set_component_module_ref(cmp_mod[:display_name], {namespace_info: cmp_mod[:namespace_name], version_info: cmp_mod[:version_info]}) }
            ret = true
          end
          
          {:changes => ret, :to_delete => to_delete, :to_add => to_add}
        end

        protected
        
        def elements_hash_form
          @elements_hash_form ||= self.module_refs_array.map { |ref| { display_name: ref[:display_name], namespace_name: ref[:namespace_info], version_info: (ref[:version_info] || DEFAULT_VERSION_INFO).to_s } }
        end
        DEFAULT_VERSION_INFO = 'master'
        
        private

        def update
          module_ref_hash_array = self.indexed_elements.map do | key, hash |
            el = hash
            unless hash[:module_name]
              el = el.merge(module_name: key.to_s)
            end
            unless hash[:module_type]
              el = el.merge(module_type: 'component')
            end
            el
          end
          ModuleRef.create_or_update(self.parent, module_ref_hash_array)
        end
        
        def get_module_ref_diffs(input_module_refs)
          diffs = {}
          
          raise_error_if_ill_formed(input_module_refs)
          
          input_module_refs.each do |ref|
            if !self.elements_hash_form.include?(ref)
              (diffs[:add] ||= []) << ref
            end
          end
          
          to_delete = self.elements_hash_form - input_module_refs
          to_delete.reject!{ |ref| IgnoreReservedModules.include?("#{ref[:namespace_name]}:#{ref[:display_name]}") }
          diffs[:delete] = to_delete unless to_delete.empty?
          
          diffs
        end
        IgnoreReservedModules = ['aws:ec2']
        
        def add_or_set_component_module_ref(module_name, mod_ref_hash)
          self[module_name] = ModuleRef.reify(self.parent.model_handle, mod_ref_hash)
        end
        
        def delete_component_module_ref(module_name)
          delete(module_name)
        end
        
        def raise_error_if_ill_formed(input_module_refs)
          input_module_refs.each do |ref|
            [:display_name, :namespace_name].each do |key|
              fail Error, "Unexpected that input_module_refs element does not have key: #{key}" unless ref[key]
            end
          end
        end
        
      end
    end
  end
end
