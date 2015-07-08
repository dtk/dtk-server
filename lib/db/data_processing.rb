
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

      def ret_convert_from_object_to_db_form(model_handle,scalar_assigns,sql_operation,opts={})
        ret = scalar_assigns
        db_rel = DB_REL_DEF[model_handle[:model_name]]
        return ret unless db_rel #to take into account model_name can be an artificial one, for example for array datasets
        # shallow copy here is sufficienct because modify_to_reflect_special_processing! only modofies at the top key level
        ret = scalar_assigns.dup
        modify_to_reflect_special_processing!(ret,db_rel,sql_operation,opts)
        ret
      end

      def json_table_column?(col,db_rel)
	return nil unless col_info = ret_table_column_info(col,db_rel)
	col_info[:type] == :json
      end

      private

      def fetch_raw_sql(sql,&block)
        @db.fetch(sql,&block)
      end

      def modify_to_reflect_special_processing!(scalar_assigns,db_rel,sql_operation,opts={})
        # TODO: below should be deprecated and use update from select form
        if opts[:shift_id_to_ancestor] and db_rel[:has_ancestor_field]
	  scalar_assigns[:ancestor_id] = scalar_assigns[:id]
        end

        if opts[:remove_ids] or opts[:shift_id_to_ancestor]
          scalar_assigns.delete(:id)
        end
        ## end area to be deprecated

        modify_for_virtual_columns!(scalar_assigns,db_rel,sql_operation,opts[:id_handle])

        if opts[:partial_value] and opts[:id_handle]
          # should only be applicable to an update
          if sql_operation == :update
            # need to get values if there are any json columns being updated and update value is array or hash
            cols_to_get = scalar_assigns.reject{|k,v|not ((v.is_a?(Hash) or v.is_a?(Array)) and json_table_column?(k,db_rel))}.keys
            unless cols_to_get.empty?
              object = get_object_scalar_columns(opts[:id_handle],Model::FieldSet.opt(cols_to_get,opts[:id_handle][:model_name]))
              object.each_key do |k|
                Aux.merge_into_json_col!(object,k,scalar_assigns[k])
                scalar_assigns[k] = object[k]
              end
            end
          else
            Log.error("partial value should only be set for an update") unless opts[:partial_value]
            Log.error("partial value should only be set when there is an id_handle in opts") unless opts[:id_handle]
          end
        end

	scalar_assigns.each_pair do |k,v|
	  if (v.is_a?(Hash) or v.is_a?(Array)) and json_table_column?(k,db_rel)
	    scalar_assigns[k] = SerializeToJSON.serialize(v)
   elsif v.respond_to?(:to_sequel)
            scalar_assigns[k] = v.to_sequel(k,sql_operation)
          end
        end

        set_updated_at!(scalar_assigns) if sql_operation == :update
        set_created_at!(scalar_assigns) if sql_operation == :create

	scalar_assigns
      end

      def set_updated_at!(update_set_clause)
        update_set_clause[:updated_at] ||= Aux::now_time_stamp()
      end

      def set_created_at!(update_set_clause)
        update_set_clause[:created_at] ||= Aux::now_time_stamp()
      end

      # if any virtual columns need to remove and populate the actual table
      def modify_for_virtual_columns!(scalar_assigns,db_rel,sql_operation,id_handle)
        # TODO: see if can leverage FieldSet
        return nil unless db_rel[:virtual_columns]
        cols = scalar_assigns.keys()
        virtual_col_defs = db_rel[:virtual_columns].reject{|k,_v|not cols.include?(k)}
        return nil if virtual_col_defs.empty?

        # if update then must do a select on all real values and set their existing value in scalar_assigns
        if sql_operation == :update
          real_cols = virtual_col_defs.values.map{|vc|vc[:path].first if vc[:path]}.compact.uniq
          unless id_handle
            Log.info("id handle should not be nil")
            return nil
          end
          object = get_object_scalar_columns(id_handle,Model::FieldSet.opt(real_cols,id_handle[:model_name]))
          object.each{|k,v| scalar_assigns[k] = v}
        end

        # delete virtual columns from scalar_assigns and appropriately set real column
        virtual_col_defs.each_key do |vc|
          vc_val = scalar_assigns.delete(vc)
          path = virtual_col_defs[vc][:path]
          unless path
            Log.info("no path definition for virtual column #{vc}")
            next
          end
          HashObject.set_nested_value!(scalar_assigns,path,vc_val)
        end
        scalar_assigns
      end

      def ret_settable_scalar_assignments(assignments,db_rel)
        ret = {}
        settable_scalar_cols = Model::FieldSet.all_settable_scalar(db_rel[:relation_type])
        assignments.each_pair do |k,v|
          next unless settable_scalar_cols.include_col?(k.to_sym)
          ret[k] = v
        end
        ret
      end

      def ret_object_assignments(assignments,db_rel)
	ret = {}
	assignments.each_pair do |k,v|
          next unless (db_rel[:one_to_many]||[]).include?(k.to_sym) and (v.is_a?(Hash) or v.is_a?(Array))
          ret[k] = v
        end
        ret
      end

      def ret_table_column_info(col,db_rel)
	return nil if db_rel[:columns].nil?
	db_rel[:columns][col.to_sym] || COMMON_REL_COLUMNS[col.to_sym]
      end
    end
  end
end
