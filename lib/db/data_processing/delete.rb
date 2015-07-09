module XYZ
  class DB
    module DataProcessingDelete
      def delete_instance(id_handle, _opts = {}) #TBD: if include opts would be for example whether containers are deleted
 # TODO: more efficient to remove this call to IDInfoTable.get_row_from_id_handl
  id_info = IDInfoTable.get_row_from_id_handle id_handle, raise_error: true
  #TBD: best practices says that one stores all resources that were present and return 200 if was to support idempotent delete
  ds = dataset(id_info[:db_rel]).where(id: id_info[:id])
  ds.delete
  nil
      end

      # assumes taht all id_handles have same model_handle
      def delete_instances(id_handles, _opts = {}) #TBD: if include opts would be for example whether containers are deleted
        return if id_handles.empty?

        sample_idh = id_handles.first
 # TODO: more efficient to remove this call to IDInfoTable.get_row_from_id_handl
  id_info = IDInfoTable.get_row_from_id_handle sample_idh, raise_error: true
  ds = dataset(id_info[:db_rel]).where(id: id_handles.map(&:get_id))
  ds.delete
  nil
      end

      # assumes taht all id_handles have same model_handle
      def delete_instances_wrt_parent(relation_type, parent_id_handle, where_clause = nil, _opts = {})
        parent_id_info = IDInfoTable.get_row_from_id_handle(parent_id_handle)
        parent_fk_col = ret_parent_id_field_name(parent_id_info[:db_rel], DB_REL_DEF[relation_type])
        c = parent_id_handle[:c]
        filter = SQL.and({ CONTEXT_ID => c }, { parent_fk_col => parent_id_info[:id] }, where_clause || {})
  ds = dataset(DB_REL_DEF[relation_type]).filter(filter)
 # Debugging
 # ds.select(:ref,:id).all.each{|obj|Log.info("deleting object with ref #{obj[:ref]} and id #{obj[:id]}")}
 ######
  ds.delete
  nil
      end
      # TODO: may deprecate above for below
      # id_rels is hash having form {:parent_id => [child_ids..], ..}
      def delete_instances_wrt_parents(parent_id_handle, parent_rel_type, child_rel_type, id_rels)
        parent_id_info = IDInfoTable.get_row_from_id_handle(parent_id_handle)
        parent_fk_col = self.class.parent_field(parent_rel_type, child_rel_type)
        disjuncts_array = id_rels.map do |(parent_id, children_ids)|
          SQL.and({ parent_fk_col => parent_id }, SQL.not(SQL.in(:id, children_ids)))
        end

        filter = SQL.and({ CONTEXT_ID => parent_id_handle[:c] }, SQL.or(*disjuncts_array))
  ds = dataset(DB_REL_DEF[child_rel_type]).filter(filter)
  ds.delete
  nil
      end
    end
  end
end
