# TODO: determine what in this file is deprecated
module DTK
  module ComponentClone
    def clone_pre_copy_hook_into_node(node, opts = {})
      workspace_cmp = self
      # check constraints
      unless opts[:no_constraint_checking]
        if constraints = workspace_cmp.get_constraints!(update_object: true)
          target = { 'target_node_id_handle' => node.id_handle_with_auth_info() }
          constraint_opts = { raise_error_when_error_violation: true, update_object: workspace_cmp }
          constraints.evaluate_given_target(target, constraint_opts)
        end
      end
      workspace_cmp
    end

    def determine_cloned_components_parent(specified_target_idh)
      # TODO: may deprecate if not using; previously mapped extensions to parents; now putting them with node as tehir parent
      return specified_target_idh if SubComponentComponentMapping.empty?
      cmp_fs = FieldSet.opt([:id, :display_name, :component_type], :component)
      specified_target_id = specified_target_idh.get_id()
      cmp_ds = Model.get_objects_just_dataset(model_handle, { id: id() }, cmp_fs)
      mapping_ds = SQL::ArrayDataset.create(self.class.db, SubComponentComponentMapping, model_handle.createMH(:mapping))

      first_join_ds =  cmp_ds.graph(:inner, mapping_ds, component: :component_type)

      parent_cmp_ds = Model.get_objects_just_dataset(model_handle, { node_node_id: specified_target_idh.get_id() }, cmp_fs)

      final_join_ds = first_join_ds.graph(:inner, parent_cmp_ds, { component_type: :parent }, convert: true)

      target_info = final_join_ds.all().first
      return specified_target_idh unless target_info
      target_info[:component2].id_handle()
    end

    SubComponentComponentMapping =
      [
        #       {:component => "postgresql__db", :parent => "postgresql__server"}
      ]

    def clone_post_copy_hook(clone_copy_output, _opts = {})
      component_idh = clone_copy_output.id_handles.first
      add_needed_sap_attributes(component_idh)
      parent_action_id_handle = id_handle().get_top_container_id_handle(:datacenter)
      StateChange.create_pending_change_item(new_item: component_idh, parent: parent_action_id_handle)
    end

    def source_clone_info_opts
      fail Error.new('component#source_clone_info_opts is deprecated')
      { ret_new_obj_with_cols: [:id, :implementation_id, :component_type, :version, :ancestor_id] }
    end

    def add_needed_sap_attributes(component_idh)
      sp_hash = {
        filter: [:and, [:oneof, :basic_type, BasicTypeInfo.keys]],
        columns: [:id, :display_name, :basic_type]
      }
      component = component_idh.get_objects_from_sp_hash(sp_hash).first
      return nil unless component

      basic_type_info = BasicTypeInfo[component[:basic_type]]
      sap_dep = basic_type_info[:sap_dependency]

      sap_info = component.get_objects_from_sp_hash(columns: [:id, :display_name, sap_dep]).first
      unless sap_info
        Log.error("error in finding sap dependencies for component #{component_idh}")
        return nil
      end

      sap_config_attr = sap_info[:attribute]
      par_attr = sap_info[:parent_attribute]
      node = sap_info[:node]

      sap_val = basic_type_info[:fn].call(sap_config_attr[:attribute_value], par_attr[:attribute_value])
      sap_attr_row = Aux.hash_subset(basic_type_info, [{ sap: :ref }, { sap: :display_name }, :description, :semantic_type, :semantic_type_summary])
      sap_attr_row.merge!(
         component_component_id: component[:id],
         value_derived: sap_val,
         is_port: true,
         hidden: true,
         data_type: 'json')

      attr_mh = component_idh.createMH(model_name: :attribute, parent_model_name: :component)
      sap_attr_idh = self.class.create_from_row(attr_mh, sap_attr_row, convert: true)

      return nil unless sap_attr_idh
      AttributeLink.create_links_sap(basic_type_info, sap_attr_idh, sap_config_attr.id_handle(), par_attr.id_handle(), node.id_handle())
    end

    protected

    def self.compute_sap_db(sap_config_val, par_vals)
      # TODO: check if it is this simple; also may not need and propagate as byproduct of adding a link
      par_vals.map { |par_val| sap_config_val.merge(par_val) }
    end

    private

    # TODO: some of these are redendant of whats in sap_dependency_X like "sap__l4" and "sap__db"
    BasicTypeInfo = {
      'database' => {
        sap_dependency: :sap_dependency_database,
        sap: 'sap__db',
        sap_config: 'sap_config__db',
        sap_config_fn_name: 'sap_config_conn__db',
        parent_attr: 'sap__l4',
        parent_fn_name: 'sap_conn__l4__db',
        semantic_type: { ':array' => 'sap__db' }, #TODO: need the  => {"application" => service qualification)
        semantic_type_summary: 'sap__db',
        description: 'DB access point',
        fn: lambda { |sap_config, par| compute_sap_db(sap_config, par) }
      }
    }
  end
end
