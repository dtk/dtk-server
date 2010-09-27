
require 'sequel'

module XYZ
  class DB
    module DataProcessingDelete
      def delete_instance(id_handle,opts={}) #TBD: if include opts would be for example whether containers are deleted
	id_info = IDInfoTable.get_row_from_id_handle id_handle, :raise_error => true
	#TBD: best practices says that one stores all resources that were present and return 200 if was to support idempotent delete
	ds = dataset(id_info[:db_rel]).where(:id => id_info[:id])
	ds.delete
	nil
      end

      def delete_instances_wrt_parent(relation_type,parent_id_handle,where_clause=nil,opts={}) 
        parent_id_info = IDInfoTable.get_row_from_id_handle(parent_id_handle)
        parent_fk_col = ret_parent_id_field_name(parent_id_info[:db_rel],DB_REL_DEF[relation_type])
        c = parent_id_handle[:c]
        filter = SQL.and({CONTEXT_ID => c},{parent_fk_col => parent_id_info[:id]},where_clause || {})
	ds = dataset(DB_REL_DEF[relation_type]).filter(filter)
        #Debugging
        #ds.select(:ref,:id).all.each{|obj|Log.info("deleting object with ref #{obj[:ref]} and id #{obj[:id]}")}
        ######
	ds.delete
	nil
      end
    end
  end
end
