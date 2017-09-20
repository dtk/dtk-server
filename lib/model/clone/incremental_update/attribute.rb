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
  class Clone::IncrementalUpdate
    class Attribute < self
      FieldsToNotCopy = [:id, :ref, :display_name, :group_id, :component_component_id, :is_port, :port_type_asserted, :value_asserted]
      FieldsModified  = [:value_derived, :value_default]
      # instance_template_links has type InstanceTemplate::Links
      def self.modify_instances(model_handle, instance_template_links)
        update_rows = instance_template_links.map { |link| update_row(link) }
        propagate_attributes(model_handle, update_rows)
        # propagate_attributes must be done before Model.update_from_rows, which updates meta info and (redundantly) updates value fields
        Model.update_from_rows(model_handle, update_rows)
      end

      private

      def self.update_row(link)
        template = link.template
        instance = link.instance
        # Using id from instance 
        # and to handle default in template that could have changed mapping template[:value_asserted] to value_derived
        # Using value_derived in case instance has value_asserted, which will override this
        default_value = template[:value_asserted]

        value_fields_update = {
          value_derived: default_value,
          value_default: default_value
        }
        Aux.hash_subset(template, template.keys - (FieldsToNotCopy + FieldsModified)).merge(id: instance.id).merge(value_fields_update)
      end


      def self.propagate_attributes(model_handle, attribute_update_rows) 
        existing_attributes = []
        ndx_new_vals        = {}
        attribute_update_rows.each do |attr_info| 
          id = attr_info[:id]
          existing_attributes << model_handle.createIDH(id: id).create_object 
          ndx_new_vals[id] = attr_info[:value_derived] 
        end
        # TODO: DTK-2601: the analog method in ib/common_dsl/object_logic/assembly/attribute/diff.rb, which processes updates when doing set attributes
        # calls 'update_and_propagate_attribute_when_node_property?'. Need to check if that method is correct and whether should be called here too
        # after update_and_propagate_attributes_from_diff
        ::DTK::Attribute.update_and_propagate_attributes_from_diff(existing_attributes, ndx_new_vals)
      end

      # TODO: put in equality test so that does not need to do the modify equal objects
      def equal_so_dont_modify?(_instance, _template)
        false
      end
      
      def update_opts
        # TODO: can refine to allow deletes if instance has nil value and not in any attribute link
        # can do this by passing in a charachterstic fn
        #{:donot_allow_deletes => true}
        super
      end
      
      def get_ndx_objects(component_idhs)
        ret = {}
        ::DTK::Component.get_attributes(component_idhs, cols_plus: [:component_component_id, :ref]).each do |r|
          (ret[r[:component_component_id]] ||= []) << r
        end
        ret
      end
    end
  end
end
