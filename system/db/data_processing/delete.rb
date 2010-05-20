require 'rubygems'
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
    end
  end
end
