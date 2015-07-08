module XYZ
  module ComponentType
    class Database < ComponentTypeHierarchy
      def self.clone_db_onto_db_server_node(db_server_node,db_server_component)
        base_sp_hash = {
          model_name: :component,
          filter: [:eq, :id, db_server_component[:ancestor_id]],
          cols: [:id,:library_library_id]
        }
        join_array =
          [{
             model_name: :attribute,
             join_type: :inner,
             alias: :db_component_name,
             filter: [:eq, :display_name, "db_component"],
             join_cond: {component_component_id: :component__id},
             cols: [:value_asserted,:component_component_id]
           },
           {
             model_name: :component,
             alias: :db_component,
             join_type: :inner,
             convert: true,
             join_cond: {display_name: :db_component_name__value_asserted, library_library_id: :component__library_library_id},
             cols: [:id,:display_name,:library_library_id]
         }
          ]

        rows = Model.get_objects_from_join_array(db_server_component.model_handle,base_sp_hash,join_array)
        db_component = rows.first && rows.first[:db_component]
        unless db_component
          Log.error("Cannot find the db component associated with the db server")
          return nil
        end
        new_db_cmp_id = db_server_node.clone_into(db_component)
        db_server_component.model_handle.createIDH(id: new_db_cmp_id)
      end
    end
  end
end
