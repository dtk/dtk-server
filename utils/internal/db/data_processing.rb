
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

      def modify_to_reflect_special_processing!(scalar_assigns,db_rel,sql_operation,opts={})
        if opts[:shift_id_to_ancestor] and db_rel[:has_ancestor_field]
	  scalar_assigns[:ancestor_id] = scalar_assigns[:id]
        end

        if opts[:remove_ids] or opts[:shift_id_to_ancestor]
          scalar_assigns.delete(:id)
        end
        
        modify_for_virtual_columns!(scalar_assigns,db_rel,sql_operation,opts[:id_handle])

	scalar_assigns.each_pair do |k,v|
	  if (v.kind_of?(Hash) or v.kind_of?(Array)) and json_table_column?(k,db_rel) 
	    scalar_assigns[k] = JSON.generate(v).to_s 
          elsif v.respond_to?(:to_sequel)
            scalar_assigns[k] = v.to_sequel(k,sql_operation)
          end
        end

	scalar_assigns
      end

      #if any virtual columns need to remove and populate the actual table 
      def modify_for_virtual_columns!(scalar_assigns,db_rel,sql_operation,id_handle)
        return nil unless db_rel[:virtual_columns]
        cols = scalar_assigns.keys()
        virtual_col_defs = db_rel[:virtual_columns].reject{|k,v|not cols.include?(k)}
        return nil if virtual_col_defs.empty?

        #if update then must do a select on all real values and set their existing value in scalar_assigns
        if sql_operation == :update
          real_cols = virtual_col_defs.values.map{|vc|vc[:path].first if vc[:path]}.compact.uniq
          unless id_handle
            Log.info("id handle shoudl not be nil")
            next
          end
          object = get_object(id_handle,{:field_set => real_cols})
          object.each{|k,v| scalar_assigns[k] = v}
        end

        #delete virtual columns from scalar_assigns and appropriately set real column
        virtual_columns.each_key do |vc|
          vc_val = scalar_assigns.delete(vc)
          path = virtual_col_defs[vc][:path]
          unless path
            Log.info("no path definition for virtual column #{virtual_col}") if ret.nil?
            next
          end
          set_nested_value(scalar_assigns,path,vc_val)
        end
        scalar_assigns
      end

      def set_nested_value(hash,path,val)
        if path.size == 0
          #TODO this should be error
        elsif path.size == 1
          hash[path.first] = val
        else
          hash[path.first] ||= Hash.new
          set_nested_value(hash[path.first],path[1..path.size-1],val)
        end
      end


      #TODO: update to reflect that virtual columns can be set
      #These are only changeable columns
      def ret_scalar_assignments(assignments,db_rel)
        ret = {}
        assignments.each_pair{|k,v| ret[k] = v if ret_table_column_info(k,db_rel) or [:description, :display_name].include?(k)}
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
