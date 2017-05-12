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
  class AttributeLinkTo < Model
    def self.common_columns
      [:id, :group_id, :display_name, :component_red]
    end


    ##########################  get links ##################
    def self.get_augmented(model_handle, filter)
      ret = []
      sp_hash = {
        cols: [:id, :group_id, :input_id, :output_id, :function, :index_map],
        filter: filter
      }
      attr_links = get_objs(model_handle, sp_hash)
      return ret if attr_links.empty?

      attr_ids = attr_links.inject([]) { |array, al| array + [al[:input_id], al[:output_id]] }
      filter = [:oneof, :id, attr_ids]
      ndx_attrs = Attribute.get_augmented(model_handle.createMH(:attribute), filter).inject({}) { |h, r| h.merge(r[:id] => r) }

      attr_links.map { |al| al.merge(input: ndx_attrs[al[:input_id]], output: ndx_attrs[al[:output_id]]) }
    end
    ########################## end: get links ##################

    ##########################  add new links ##################
    def self.create_from_link_defs__clone_if_needed(parent_idh, link_def_context, opts = {})
      #TODO: might put back in on_create_events.each{|ev|ev.process!(context)}

      # ret_links__clone_if_needed returns array of type LinkDef::Link::AttributeMapping::AugmentedLinkContext
      # which has attribute_mapping plus needed context
      aug_am_links = link_def_context.aug_attr_mappings__clone_if_needed(opts)
      create_attribute_links(parent_idh, aug_am_links)
   end

    def self.create_attribute_links(parent_idh, rows_to_create, opts = {})
      return [] if rows_to_create.empty?
      attr_mh = parent_idh.create_childMH(:attribute)
      attr_link_mh = parent_idh.create_childMH(:attribute_link)

      attr_info = create_attribute_links__attr_info(attr_mh, rows_to_create, opts)
      add_link_fns!(rows_to_create, attr_info)

      # add parent_col and ref
      parent_col = attr_link_mh.parent_id_field_name()
      parent_id = parent_idh.get_id()
      rows_to_create.each do |row|
        row[parent_col] ||= parent_id
        row[:ref] ||= "attribute_link:#{row[:input_id]}-#{row[:output_id]}"
      end

      # actual create of new attribute_links
      rows_for_array_ds = rows_to_create.map { |row| Aux.hash_subset(row, row.keys - remove_keys) }
      select_ds = SQL::ArrayDataset.create(db, rows_for_array_ds, attr_link_mh, convert_for_create: true)
      override_attrs = {}
      field_set = FieldSet.new(model_name, rows_for_array_ds.first.keys)
      returning_ids = create_from_select(attr_link_mh, field_set, select_ds, override_attrs, returning_sql_cols: [:id])

      # insert the new ids into rows_to_create
      returning_ids.each_with_index { |id_info, i| rows_to_create[i][:id] = id_info[:id] }

      # augment attributes with port info; this is needed only if port is external
      Attribute.update_port_info(attr_mh, rows_to_create) unless opts[:donot_update_port_info]

      # want to use auth_info from parent_idh in case more specific than target
      change_parent_idh = parent_idh.get_top_container_id_handle(:target, auth_info_from_self: true)
      # propagate attribute values
      ndx_nested_change_hashes = propagate_from_create_and_update_index_maps(attr_mh, attr_info, rows_to_create, change_parent_idh)
      StateChange.create_pending_change_items(ndx_nested_change_hashes.values) unless opts[:donot_create_pending_changes]
    end


  end
end