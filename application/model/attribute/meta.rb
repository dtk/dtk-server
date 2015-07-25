# TODO: temp until move into meta directory
module XYZ; class Attribute
  # TOOD: hack taht can be removed when update_object allows virtual types
  module VirtulaDependency
    def self.port_type
      [:dynamic, :is_port, :port_type_asserted, :semantic_type_summary]
    end
  end

  module MetaClassMixin
    def up
      external_ref_column_defs()
      virtual_column :config_agent_type, type: :string, local_dependencies: [:external_ref]
      virtual_column :title, type: :string, local_dependencies: [:value_asserted, :value_derived, :external_ref, :display_name]

      # columns related to the value
      column :value_asserted, :json, ret_keys_as_symbols: false
      column :value_derived, :json, ret_keys_as_symbols: false
      column :is_instance_value, :boolean, default: false #to distinguish between when value_asserted is from default versus directly asserted
      # TODO: not used yet column :value_actual, :json, :ret_keys_as_symbols => false
      # TODO: may rename attribute_value to desired_value
      virtual_column :attribute_value, type: :json, local_dependencies: [:value_asserted, :value_derived],
                                       sql_fn: SQL::ColRef.coalesce(:value_asserted, :value_derived)

      # TODO: should collapse the semantic types
      # columns related to the data/semantic type
      column :data_type, :varchar, size: 25
      column :semantic_data_type, :varchar, size: 25
      column :semantic_type, :json #points to structural info for a json var
      column :semantic_type_summary, :varchar, size: 25 #for efficiency optional token that summarizes info from semantic_type
      virtual_column :semantic_type_object, type: :object, hidden: true, local_dependencies: [:semantic_type]

      # TODO: may be able to remove some feilds and use tags to store them
      column :tags, :json

      ###cols that relate to who or what can or does change the attribute
      # TODO: need to clearly relate these four; may get rid of read_only
      column :read_only, :boolean, default: false
      column :dynamic, :boolean, default: false #means dynamically set by an executable action
      column :cannot_change, :boolean, default: false

      column :required, :boolean, default: false #whether required for this attribute to have a value inorder to execute actions for parent component; TODO: may be indexed by action
      column :hidden, :boolean, default: false

      # columns related to links
      # TODO: for succinctness may use less staorage and colapse a number of port attributes
      column :port_location, :varchar, size: 10 #if set is override for port direction: east | west | south | north
      column :is_port, :boolean, default: false
      column :port_type_asserted, :varchar, size: 10
      column :is_external, :boolean

      virtual_column :port_type, type: :varchar, hidden: true, local_dependencies: VirtulaDependency.port_type()

      virtual_column :port_is_external, type: :boolean, hidden: true, local_dependencies: [:is_port, :is_external, :semantic_type_summary]

      virtual_column :is_unset, type: :boolean, hidden: true, local_dependencies: [:value_asserted, :value_derived, :data_type, :semantic_type]

      virtual_column :parent_name, possible_parents: [:component, :node]
      many_to_one :component, :node, :action_def
      one_to_many :dependency #for ports indicating what they can connect to

      virtual_column :dependencies, type: :json, hidden: true,
                                    remote_dependencies:         [
         {
           model_name: :dependency,
           alias: :dependencies,
           convert: true,
           join_type: :inner,
           join_cond: { attribute_attribute_id: q(:attribute, :id) },
           cols: [:id, :search_pattern, :type, :description, :severity]
         }]

      virtual_column :component_parent, type: :json, hidden: true,
                                        remote_dependencies:         [
         {
           model_name: :component,
           alias: :component_parent,
           convert: true,
           join_type: :left_outer,
           join_cond: { id: p(:attribute, :component) },
           cols: [:id, :display_name, :component_type, :most_specific_type, :connectivity_profile_external, :ancestor_id, :node_node_id, :extended_base_id]
         }]

        virtual_column :component_module_parent, type: :json, hidden: true,
                                                 remote_dependencies:           [
           {
             model_name: :component,
             join_type: :inner,
             join_cond: { id: :attribute__component_component_id },
             cols: [:id, :display_name, :module_branch_id]
           },
           {
             model_name: :module_branch,
             join_type: :inner,
             join_cond: { id: :component__module_branch_id },
             cols: [:id, :component_id]
           }
          ]

      # finds both component parents with node and dircet node parent
      virtual_column :node_component_info, type: :json, hidden: true,
                                           remote_dependencies:         [{
           model_name: :node,
           convert: true,
           alias: :direct_node,
           join_type: :left_outer,
           join_cond: { id: p(:attribute, :node) },
           cols: [:id, :display_name, :group_id]
         },
                                                                         {
                                                                           model_name: :component,
                                                                           convert: true,
                                                                           join_type: :left_outer,
                                                                           join_cond: { id: p(:attribute, :component) },
                                                                           cols: [:id, :display_name, :group_id, :component_type, :node_node_id]
                                                                         },
                                                                         {
                                                                           model_name: :node,
                                                                           convert: true,
                                                                           alias: :component_node,
                                                                           join_type: :left_outer,
                                                                           join_cond: { id: p(:component, :node) },
                                                                           cols: [:id, :display_name, :group_id]
                                                                         }]

      virtual_column :port_info, type: :boolean, hidden: true,
                                 remote_dependencies:         [
         {
           model_name: :port,
           alias: :port_external,
           join_type: :inner,
           filter: [:eq, :type, 'external'],
           join_cond: { external_attribute_id: q(:attribute, :id) },
           cols: [:id, :type, id(:node), :containing_port_id, :external_attribute_id, :ref]
         },
         {
           model_name: :port,
           alias: :port_l4,
           join_type: :left_outer,
           filter: [:eq, :type, 'l4'],
           join_cond: { id: q(:port_external, :containing_port_id) },
           cols: [:id, :type, id(:node), :containing_port_id, :external_attribute_id, :ref]
         }]

      uri_remote_dependencies =
        { uri:         [
         {
           model_name: :id_info,
           join_cond: { relation_id: :attribute__id },
           cols: [:relation_id, :uri]
         }
        ]
      }
      virtual_column :id_info_uri, hidden: true, remote_dependencies: uri_remote_dependencies

      virtual_column :unraveled_attribute_id, type: :varchar, hidden: true #TODO: put in depenedncies

      # TODO: may deprecate
      virtual_column :qualified_attribute_name_under_node, type: :varchar, hidden: true #TODO: put in depenedncies
      virtual_column :qualified_attribute_id_under_node, type: :varchar, hidden: true #TODO: put in depenedncies
      virtual_column :qualified_attribute_name, type: :varchar, hidden: true #not giving dependences because assuming right base_object included in col list

      virtual_column :linked_attributes, type: :json, hidden: true,
                                         remote_dependencies:         [
         {
           model_name: :attribute_link,
           join_type: :inner,
           join_cond: { output_id: :attribute__id },
           cols: [:output_id, :input_id, :function, :index_map]
         },
         {
           model_name: :attribute,
           alias: :input_attribute,
           join_type: :inner,
           join_cond: { id: :attribute_link__input_id },
           cols: [:id, :value_asserted, :value_derived, :semantic_type, :display_name]
         }
        ]
    end
  end
end; end
