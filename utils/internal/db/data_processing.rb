
require 'sequel'
require File.expand_path('rest_content', File.dirname(__FILE__))
require File.expand_path('data_processing/get', File.dirname(__FILE__))
require File.expand_path('data_processing/create', File.dirname(__FILE__))
require File.expand_path('data_processing/delete', File.dirname(__FILE__))
require File.expand_path('data_processing/update', File.dirname(__FILE__))

module XYZ
  class DB
    module DataProcessing
      include RestContent unless included_modules.include?(RestContent)
      include DataProcessingCreate unless included_modules.include?(DataProcessingCreate)
      include DataProcessingGet unless included_modules.include?(DataProcessingGet)
      include DataProcessingDelete unless included_modules.include?(DataProcessingDelete)
      include DataProcessingUpdate unless included_modules.include?(DataProcessingUpdate)

      def dataset(db_rel,table_alias=nil)
        @db.from(db_rel.schema_table_symbol(table_alias)) 
      end
     private

      def modify_to_reflect_special_processing!(scalar_assigns,db_rel,opts={})
        if opts[:shift_id_to_ancestor] and db_rel[:has_ancestor_field]
	  scalar_assigns[:ancestor_id] = scalar_assigns[:id]
        end

        if opts[:remove_ids] or opts[:shift_id_to_ancestor]
          scalar_assigns.delete(:id)
        end

	scalar_assigns.each_pair{|k,v|
	  if (v.kind_of?(Hash) or v.kind_of?(Array)) and json_table_column?(k,db_rel) 
	    scalar_assigns[k] = JSON.generate(v).to_s 
          end
        }

	scalar_assigns
      end

      #THese are only changeable columns
      def ret_scalar_assignments(assignments,db_rel)
        ret = {}
        assignments.each_pair{|k,v| ret[k] = v if ret_table_column_info(k,db_rel) or %w{description display_name}.include?(k)}
        ret
      end	
      def ret_object_assignments(assignments,db_rel)
	ret = {}
	assignments.each_pair{|k,v| ret[k] = v if table_child_object?(k,db_rel) and 
	                      (v.kind_of?(Hash) or v.kind_of?(Array))}
        ret
      end	

      def ret_table_column_info(col,db_rel)
	return nil if db_rel[:columns].nil?
	db_rel[:columns][col.to_sym] || COMMON_REL_COLUMNS[col.to_sym]
      end

      def json_table_column?(col,db_rel)
	return nil unless col_info = ret_table_column_info(col,db_rel)
	col_info[:type] == :json
      end

      def table_child_object?(col,db_rel)
	return nil if db_rel[:one_to_many].nil?
	db_rel[:one_to_many].include?(col.to_sym)
      end
    end
  end
end
