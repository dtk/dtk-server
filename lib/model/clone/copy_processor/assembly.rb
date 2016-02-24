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
  class Clone
    class CopyProcessor
      class Assembly < self
        def cloning_assembly?
          true
        end

        def clone_direction
          :library_to_target
        end

        attr_reader :project, :component_module_refs

        private

        def initialize(target_obj, source_obj, opts = {})
          super(source_obj, opts)
          @project = (target_obj.respond_to?(:get_project) && target_obj.get_project)
          @component_module_refs = get_component_module_refs(source_obj)
        end

        def get_component_module_refs(source_obj)
          sp_hash = {
            cols: [:id, :group_id, :display_name],
            filter: [:eq, :id, source_obj.get_field?(:module_branch_id)]
          }
          branch = Model.get_obj(source_obj.model_handle(:module_branch), sp_hash)
          ModuleRefs.get_component_module_refs(branch)
        end

        def get_nested_objects_top_level(model_handle, target_parent_mh, assembly_objs_info, recursive_override_attrs, &block)
          fail Error.new('Not treating assembly_objs_info with more than 1 element') unless assembly_objs_info.size == 1
          assembly_obj_info = assembly_objs_info.first
          get_nested_objects_top_level_aux(model_handle, target_parent_mh, assembly_obj_info, recursive_override_attrs, &block)
          override_attrs = {}
          opts_generate = { include_list: [:attribute, :task_template], standard_child_context: true }
          ChildContext.generate(self, model_handle, [assembly_obj_info], override_attrs, opts_generate, &block)
        end

        def get_nested_objects_top_level_aux(model_handle, target_parent_mh, assembly_obj_info, recursive_override_attrs, &block)
          ancestor_id = assembly_obj_info[:ancestor_id]
          target_parent_mn = target_parent_mh[:model_name]
          model_name = model_handle[:model_name]
          new_assembly_assign = { assembly_id: assembly_obj_info[:id] }
          new_par_assign = { DB.parent_field(target_parent_mn, model_name) => assembly_obj_info[:parent_id] }
          Global::AssemblyChildren.each do |nested_model_name|
            # TODO: push this into ChildContext.create_from_hash
            nested_mh = model_handle.createMH(model_name: nested_model_name, parent_model_name: target_parent_mn)
            override_attrs = new_assembly_assign.merge(ret_child_override_attrs(nested_mh, recursive_override_attrs))
            create_opts = { duplicate_refs: :allow, returning_sql_cols: [:ancestor_id, :assembly_id] }

            # putting in nulls to null-out; more efficient to omit this columns in create
            parent_rel = (DB_REL_DEF[nested_model_name][:many_to_one] || []).inject({ old_par_id: ancestor_id }) do |hash, pos_par|
              hash.merge(Model.matching_models?(pos_par, target_parent_mn) ? new_par_assign : { DB.parent_field(pos_par, model_name) => SQL::ColRef.null_id })
            end
            if Model.matching_models?(nested_model_name, :node)
              unless (override_attrs[:component] || {})[:assembly_id]
                override_attrs.merge!(component: new_assembly_assign)
              end
            end
            target_idh = target_parent_mh.createIDH(id: assembly_obj_info[:parent_id])
            child_hash = {
              assembly_obj_info: assembly_obj_info,
              model_handle: nested_mh,
              clone_par_col: :assembly_id,
              parent_rels: [parent_rel],
              override_attrs: override_attrs,
              create_opts: create_opts,
              ancestor_id: ancestor_id,
              target_idh: target_idh
            }
            block.call(ChildContext.create_from_hash(self, child_hash))
          end
        end
      end
    end
  end
end
