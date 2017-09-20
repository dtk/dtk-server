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
  class Clone::ChildContext
    class AssemblyComponentAttribute < self
      private

      def ret_new_objs_info(field_set_to_copy, create_override_attrs)
        new_objs_info = super
        return new_objs_info if new_objs_info.empty?
        process_attribute_overrides(new_objs_info)
        new_objs_info
      end

      def process_attribute_overrides(new_objs_info)
        fs_select =
          [
           :display_name,
           :component_ref_id,
           :tags,
           # Lines below set is_instance_value and sets value_asserted when directly set value (in contrast to an inherited default)
           { SQL.not(attribute_value: nil) => :is_instance_value },
           { attribute_value: :value_asserted }
          ]

        attr_override_fs = Model::FieldSet.new(:attribute_override, fs_select)

        attr_override_wc = nil
        attr_override_ds = Model.get_objects_just_dataset(self.attribute_override_mh, attr_override_wc, Model::FieldSet.opt(attr_override_fs))

        cmp_mapping_rows = parent_objs_info.map { |r| Aux.hash_subset(r, [:component_ref_id, { id: :component_component_id }]) }
        cmp_mapping_ds = array_dataset(cmp_mapping_rows, :cmp_mapping)

        attr_mapping_rows = new_objs_info.map { |r| Aux.hash_subset(r, [:component_component_id, :display_name, :id]) }
        attr_mapping_ds = array_dataset(attr_mapping_rows, :attr_mapping)

        select_ds = attr_override_ds.join_table(:inner, cmp_mapping_ds, [:component_ref_id]).join_table(:inner, attr_mapping_ds, [:component_component_id, :display_name])
        update_set_fs = Model::FieldSet.new(:attribute, [:tags, :is_instance_value, :value_asserted])
        Model.update_from_select(self.attribute_mh, update_set_fs, select_ds)

        # TODO: converts above to below simpler form

        values_info = default_values_info(new_objs_info) 
        unless values_info.empty?
          update_rows = values_info.map do |value_info| 
            default_value = value_info.value
            {
              id: value_info.id,
              value_asserted: nil,
              value_default: default_value,
              value_derived: default_value,
            }
          end
          Model.update_from_rows(self.attribute_mh, update_rows)
        end 
      end

      DEFAULT_COL_IN_ATTR_TEMPLATE = :value_asserted
      ValueInfo = Struct.new(:id, :value)
      def default_values_info(new_objs_info)
        sp_hash = {
          cols: [:id, :is_instance_value, DEFAULT_COL_IN_ATTR_TEMPLATE], 
          filter: [:oneof, :id, new_objs_info.map { |obj| obj[:id] }]
        }
        ret = []
        Model.get_objs(attribute_mh, sp_hash).each do |attribute| 
          value = attribute[DEFAULT_COL_IN_ATTR_TEMPLATE] 
          ret << ValueInfo.new(attribute.id, value) unless value.nil? or attribute[:is_instance_value]
        end
        ret
      end

      protected

      def attribute_mh
        @attribute_mh = model_handle.createMH(:attribute)
      end
      
      def attribute_override_mh
        @attribute_override_mh ||= model_handle.createMH(:attribute_override)
      end

    end
  end
end
