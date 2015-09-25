module DTK
  class AttributeLink < Model
    r8_nested_require('attribute_link', 'propagate_mixins')
    r8_nested_require('attribute_link', 'propagate_changes')
    r8_nested_require('attribute_link', 'function')
    r8_nested_require('attribute_link', 'update_delta')
    r8_nested_require('attribute_link', 'index_map')
    r8_nested_require('attribute_link', 'propagate_processor')
    r8_nested_require('attribute_link', 'ad_hoc')

    def self.common_columns
      [:id, :group_id, :display_name, :input_id, :output_id, :type, :hidden, :function, :index_map, :assembly_id, :port_link_id]
    end

    # virtual attribute defs
    def output_index_map
      index_map_aux(:output)
    end

    def input_index_map
      index_map_aux(:input)
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

    def self.attribute_info_cols
      [:id, :attribute_value, :semantic_type_object, :component_parent]
    end
    
    def self.propagate_and_update_index_maps!(attrs_links_to_update, attr_mh)
      PropagateChanges.propagate_and_update_index_maps!(attrs_links_to_update, attr_mh)
    end

    def self.update_for_delete_links(attr_mh, aug_attr_links, opts = {})
      UpdateDelta.update_for_delete_links(attr_mh, aug_attr_links, opts)
    end

    private

    def index_map_aux(input_or_output)
      if index_map = get_field?(:index_map)
        unless index_map.size == 1
          Log.error('Not treating item map with size greater than 1')
          return nil
        end
        ret = index_map.first[input_or_output]
        (!ret.empty?) && ret
      end
    end

    # this propagates changes and updates each attribute link's index_map
    def  self.propagate_from_create_and_update_index_maps(attr_mh, attr_info, attr_links, change_parent_idh)
      attrs_links_to_update = attr_links.map do |attr_link|
        input_attr = attr_info[attr_link[:input_id]]
        output_attr = attr_info[attr_link[:output_id]]
        {
          input_attribute: input_attr,
          output_attribute: output_attr,
          attribute_link: attr_link,
          parent_idh: change_parent_idh
        }
      end
      propagate_and_update_index_maps!(attrs_links_to_update, attr_mh)
    end

    # mechanism to compensate for fact that cols are being added by processing fns to rows_to_create that
    # must be removed before they are saved
    RemoveKeys = []
    def self.remove_keys
      RemoveKeys
    end
    def self.add_to_remove_keys(*keys)
      keys.each { |k| RemoveKeys << k unless RemoveKeys.include?(k) }
    end

    def self.get_attribute_info(attr_mh, rows_to_create)
      endpoint_ids = rows_to_create.map { |r| [r[:input_id], r[:output_id]] }.flatten.uniq
      sp_hash = {
        cols: attribute_info_cols(),
        filter: [:oneof, :id, endpoint_ids]
      }
      get_objs(attr_mh, sp_hash)
    end

    def self.check_constraints(attr_mh, rows_to_create)
      # TODO: may modify to get all constraints from  conn_info_list
      rows_to_create.each do |row|
        # TODO: right now constraints just on input, not output, attributes
        attr = attr_mh.createIDH(id: row[:input_id]).create_object()
        constraints = Constraints.new()
        if row[:link_defs]
          unless row[:conn_info]
           constraints << Constraint::Macro.no_legal_endpoints(row[:link_defs])
          end
        end
        next if constraints.empty?
        target = { target_port_id_handle: attr_mh.createIDH(id: row[:output_id]) }
        # TODO: may treat differently if rows_to_create has multiple rows
        constraints.evaluate_given_target(target, raise_error_when_error_violation: true)
      end
    end

    def self.create_attribute_links__attr_info(attr_mh, rows_to_create, opts = {})
      attr_rows = opts[:attr_rows] || get_attribute_info(attr_mh, rows_to_create)
      attr_rows.inject({}) { |h, attr| h.merge(attr[:id] => attr) }
    end

    def self.add_link_fns!(rows_to_create, attr_info)
      rows_to_create.each do |r|
        input_attr = attr_info[r[:input_id]].merge(r[:input_path] ? { input_path: r[:input_path] } : {})
        output_attr = attr_info[r[:output_id]].merge(r[:output_path] ? { output_path: r[:output_path] } : {})
        r[:function] ||= Function.link_function(r, input_attr, output_attr)
      end
    end

    add_to_remove_keys :input_path, :output_path

    ####################

    public

    ### special purpose create links ###
    def self.create_links_node_group_members(node_group_id_handle, ng_cmp_id_handle, node_cmp_id_handles)
      node_cmp_mh = node_cmp_id_handles.first.createMH
      node_cmp_wc = { ancestor_id: ng_cmp_id_handle.get_id() }
      node_cmp_fs = FieldSet.opt([:id], :component)
      node_cmp_ds = get_objects_just_dataset(node_cmp_mh, node_cmp_wc, node_cmp_fs)

      attr_mh = node_cmp_mh.create_childMH(:attribute)

      attr_parent_col = attr_mh.parent_id_field_name()
      node_attr_fs = FieldSet.opt([attr_parent_col, :id, :ref], :attribute)
      node_attr_ds = get_objects_just_dataset(attr_mh, nil, node_attr_fs)

      group_attr_wc = { attr_parent_col => ng_cmp_id_handle.get_id() }
      group_attr_fs = FieldSet.opt([:id, :ref], :attribute)
      group_attr_ds = get_objects_just_dataset(attr_mh, group_attr_wc, group_attr_fs)

      # attribute link has same parent as node_group
      attr_link_mh = node_group_id_handle.create_peerMH(:attribute_link)
      attr_link_parent_id_handle = node_group_id_handle.get_parent_id_handle()
      attr_link_parent_col = attr_link_mh.parent_id_field_name()
      ref_prefix = 'attribute_link:'
      i1_ds = node_cmp_ds.select(
         { SQL::ColRef.concat(ref_prefix, :input__id.cast(:text), '-', :output__id.cast(:text)) => :ref },
         { attr_link_parent_id_handle.get_id() => attr_link_parent_col },
         { input__id: :input_id },
         { output__id: :output_id },
         { 'member' => :type },
         'eq' => :function)
      first_join_ds = i1_ds.join_table(:inner, node_attr_ds, { attr_parent_col => :id }, table_alias: :input)
      attr_link_ds = first_join_ds.join_table(:inner, group_attr_ds, [:ref], table_alias: :output)

      attr_link_fs = FieldSet.new(:attribute, [:ref, attr_link_parent_col, :input_id, :output_id, :function, :type])
      override_attrs = {}

      opts = { duplicate_refs: :no_check, returning_sql_cols: [:input_id, :output_id] }
      create_from_select(attr_link_mh, attr_link_fs, attr_link_ds, override_attrs, opts)
    end

    def self.create_links_sap(link_info, sap_attr_idh, sap_config_attr_idh, par_idh, node_idh)
      attr_link_mh = sap_attr_idh.createMH(model_name: :attribute_link, parent_model_name: :node)
      sap_id, sap_config_id, par_id, node_id = [sap_attr_idh, sap_config_attr_idh, par_idh, node_idh].map(&:get_id)

      sap_config_name = link_info[:sap_config]
      sap_name = link_info[:sap]
      parent_attr_name = link_info[:parent_attr_name]

      new_link_rows =
        [
         {
           ref: "#{sap_config_name}:#{sap_config_id}-#{sap_id}",
           display_name: "link:#{sap_config_name}-#{sap_name}",
           input_id: sap_id,
           output_id: sap_config_id,
           type: 'internal',
           hidden: true,
           function: link_info[:sap_config_fn_name],
           node_node_id: node_id
         },
         {
           ref: "#{parent_attr_name}:#{par_id}-#{sap_id}",
           display_name: "link:#{parent_attr_name}-#{sap_name}",
           input_id: sap_id,
           output_id: par_id,
           type: 'internal',
           hidden: true,
           function: link_info[:parent_fn_name],
           node_node_id: node_id
         }
        ]
      create_from_rows(attr_link_mh, new_link_rows)
    end

    # TODO: deprecate below after subsuming from above
    def self.create_links_l4_sap(new_sap_attr_idh, sap_config_attr_idh, ipv4_host_addrs_idh, node_idh)
      attr_link_mh = node_idh.createMH(model_name: :attribute_link, parent_model_name: :node)
      new_sap_id, sap_config_id, ipv4_id, node_id = [new_sap_attr_idh, sap_config_attr_idh, ipv4_host_addrs_idh, node_idh].map(&:get_id)

      new_link_rows =
        [
         {
           ref: "sap_config:#{sap_config_id}-#{new_sap_id}",
           display_name: 'link:sap_config-sap',
           input_id: new_sap_id,
           output_id: sap_config_id,
           type: 'internal',
           hidden: true,
           function: 'sap_config__l4',
           node_node_id: node_id
         },
         {
           ref: "host_address:#{ipv4_id}-#{new_sap_id}",
           display_name: 'link:host_address-sap',
           input_id: new_sap_id,
           output_id: ipv4_id,
           type: 'internal',
           hidden: true,
           function: 'host_address_ipv4',
           node_node_id: node_id
         }
        ]
      create_from_rows(attr_link_mh, new_link_rows)
    end

    ########################## end add new links ##################


    ######################## TODO: see which of below are still used
    def self.get_legal_connections(parent_id_handle)
      c = parent_id_handle[:c]
      parent_id = IDInfoTable.get_id_from_id_handle(parent_id_handle)
      component_ds = get_objects_just_dataset(ModelHandle.new(c, :component), nil, { parent_id: parent_id }.merge(FieldSet.opt([:id, :external_ref], :component)))
      attribute_ds = get_objects_just_dataset(ModelHandle.new(c, :attribute), nil, FieldSet.opt([:id, :external_ref, :component_component_id], :attribute))

      attribute_link_ds = get_objects_just_dataset(ModelHandle.new(c, :attribute_link))
      component_ds.graph(:inner, attribute_ds, { component_component_id: :id }).graph(:left_outer, attribute_link_ds, input_id: :id).where(attribute_link__id: nil).all
    end

    def self.get_legal_connections_wrt_endpoint(_attribute_id_handle, _parent_id_handle)
    end

    private

    def self.ret_function_if_can_determine(input_obj, output_obj)
      i_sem = input_obj[:semantic_type]
      return nil if i_sem.nil?
      o_sem = output_obj[:semantic_type]
      return nil if o_sem.nil?

      # TBD: haven't put in any rules if they have different seamntic types
      return nil unless i_sem.keys.first == o_sem.keys.first

      sem_type = i_sem.keys.first
      ret_function_endpoints_same_type(i_sem[sem_type], o_sem[sem_type])
    end

    def self.ret_function_endpoints_same_type(i, o)
      # TBD: more robust is allowing for example output to be "database", which matches with "postgresql" and also to have version info, etc
      fail Error.new('mismatched input and output types') unless i[:type] == o[:type]
      return :equal if !i[:is_array] && !o[:is_array]
      return :equal if i[:is_array] && o[:is_array]
      return :concat if !i[:is_array] && o[:is_array]
      fail Error.new('mismatched input and output types') if i[:is_array] && !o[:is_array]
      nil
    end

    def get_input_attribute(_opts = {})
      return nil if self[:input_id].nil?
      get_object_from_db_id(self[:input_id], :attribute)
    end

    def get_output_attribute(_opts = {})
      return nil if self[:output_id].nil?
      get_object_from_db_id(self[:output_id], :attribute)
    end
  end
end
