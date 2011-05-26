module XYZ
  class DB
    module DataProcessingUpdate
      def update_from_select(model_handle,field_set,select_ds,opts={})
        columns = field_set.cols
        #TODO: right now need to hardwire to t1 for this to work; although alias set with this var; adding where clause puts t1 in
        select_prefix = :t1
        update_table_prefix = :update_table
#        sequel_select = select_ds.sequel_ds.ungraphed.from_self(:alias => select_prefix) #ungraphed and from_self just to be safe
        sequel_select = select_ds.sequel_ds.ungraphed.from_self #ungraphed and from_self just to be safe
        db_rel = DB_REL_DEF[model_handle[:model_name]]

        wc = {"#{update_table_prefix}__id".to_sym => "#{select_prefix}__id".to_sym}
        ch_cols = opts[:update_only_if_change]
        if ch_cols
          wc_add = ch_cols.map{|col|SQL.not_equal("#{update_table_prefix}__#{col}".to_sym,"#{select_prefix}__#{col}".to_sym)}
          wc = SQL.and(*([wc]+wc_add))
        end

        update_ds = dataset(db_rel,update_table_prefix,sequel_select).where(wc)
        update_set_clause = columns.inject({}){|hash,col| hash.merge(col => "#{select_prefix}__#{col}".to_sym)}

        set_updated_at!(update_set_clause)

        unless opts[:returning_cols] 
          update_ds.update(update_set_clause)
          return nil
        end
        unless respond_to?(:update_returning_sql)
          raise Error.new("have not implemented update_from_select with returning opt")
        end
        ret_list_prefixed = opts[:returning_cols].map{|x|x.kind_of?(Hash) ? {"#{select_prefix}__#{Aux::ret_key(x)}".to_sym => Aux::ret_value(x)} : "#{select_prefix}__#{x}".to_sym}
        sql = update_returning_sql(update_ds,update_set_clause,ret_list_prefixed)
        ret = Array.new
        fetch_raw_sql(sql){|row| ret << row}
        ret
      end


      def update_rows_meeting_filter(model_handle,scalar_assignments,where_clause,opts={})
        #TODO: not treating opts yet or conversion from json form
        update_set_clause = scalar_assignments
        set_updated_at!(update_set_clause)
        db_rel = DB_REL_DEF[model_handle[:model_name]]
        update_ds = dataset(db_rel).where(where_clause)
        update_ds.update(update_set_clause)
        nil
      end

      #TODO Enable short circuit that conditionally avoids IDInfoTable
      #returns list of created uris
      def update_from_hash_assignments(id_handle,hash_assigns,opts={})
	id_info = IDInfoTable.get_row_from_id_handle id_handle, :raise_error => true 
	return update_from_hash_from_factory_id(id_info,id_handle,hash_assigns,opts) if id_info[:is_factory]
        update_from_hash_from_instance_id(id_info,id_handle,hash_assigns,opts)
      end

      #TODO Enable short circuit that conditionally avoids IDInfoTable
      #TDOD may remove below two public methods and subsume by above
      def update_instance(id_handle,scalar_assigns,opts={}) 
	id_info = IDInfoTable.get_row_from_id_handle id_handle, :raise_error => true
	update_instance_from_id_info(id_info,scalar_assigns,opts)
      end
    
      def update(relation_type,c,scalar_assigns,where_clause={})
	db_rel = DB_REL_DEF[relation_type]
	ds = dataset(db_rel).where(SQL.and(where_clause,{CONTEXT_ID => c}))
	#TODO: check that valid assigns
	modify_to_reflect_special_processing!(scalar_assigns,db_rel,:update)
	ds.update(scalar_assigns)
      end

     private

      def set_updated_at!(update_set_clause)
        update_set_clause[:updated_at] = SQL.now unless update_set_clause[:updated_at]
      end

      def update_given_sequel_dataset(id_info,update_ds,update_set_clause,opts={})
        unless opts[:returning_cols] 
          update_ds.update(update_set_clause)
          return nil
        end
        unless respond_to?(:update_returning_sql)
          raise Error.new("have not implemented update_from_select with returning opt")
        end
        ret_list_prefixed = opts[:returning_cols].map{|x|x.kind_of?(Hash) ? {"#{select_prefix}__#{Aux::ret_key(x)}".to_sym => Aux::ret_value(x)} : "#{select_prefix}__#{x}".to_sym}
        sql = update_returning_sql(update_ds,update_set_clause,ret_list_prefixed)
        ret = Array.new
        fetch_raw_sql(sql){|row| ret << row}
        db_rel = DB_REL_DEF[id_info[:relation_type]]
	modify_to_reflect_special_processing!(ret,db_rel,:update)
        ret
      end

      def update_instance_from_id_info(id_info,scalar_assigns,opts={})
	return nil if scalar_assigns.empty?
	db_rel = DB_REL_DEF[id_info[:relation_type]]
	ds = dataset(db_rel).where(:id => id_info[:id])
	#TODO: check that valid assigns
        id_handle = IDHandle[:id_info => id_info]
	modify_to_reflect_special_processing!(scalar_assigns,db_rel,:update,opts.merge({:id_handle => id_handle}))
	ds.update(scalar_assigns)
      end


      #id_handle used to pass context such as user_id and group_id
      #TODO: may collapse factory_id_info and id_handle
      def update_from_hash_from_factory_id(factory_id_info,id_handle,assigns,opts={})
        new_uris = Array.new
        delete_not_matching = (assigns.kind_of?(HashObject) and assigns.is_complete?)
	c = factory_id_info[:c]
        child_id_list = Array.new
	#each assigns key should be qualified ref wrt factory_id
        assigns.each_pair do |qualified_ref,child_assigns|
	  child_uri = RestURI.ret_child_uri_from_qualified_ref(factory_id_info[:uri],qualified_ref)
	  child_id_info = IDInfoTable.get_row_from_id_handle IDHandle[:c => c, :uri => child_uri]
          if child_id_info
	    update_from_hash_from_instance_id(child_id_info,id_handle,child_assigns,opts)
            child_id_list << child_id_info[:id] if delete_not_matching
          else
            unless assigns.kind_of?(HashObject) and assigns.do_not_extend
              factory_id_handle = id_handle.createIDH(:uri => factory_id_info[:uri], :is_factory => true) 
              create_uris = create_from_hash(factory_id_handle,{qualified_ref => child_assigns}).map{|r|r[:uri]}
              new_uris = new_uris + create_uris
            end
          end

	end
        if delete_not_matching
          #at this point child_list will just have existing items; need to add new items
          new_child_ids = new_uris.map{|uri| IDHandle[:c => c, :uri => uri].get_id()}
          child_id_list = child_id_list + new_child_ids
          delete_not_matching_children(child_id_list,factory_id_info,assigns,opts) 
        end
        new_uris
      end

      def delete_not_matching_children(child_id_list,factory_id_info,assigns,opts={})
        parent_id_handle = IDHandle[:c => factory_id_info[:c], :guid => factory_id_info[:parent_id]]
        relation_type = factory_id_info[:relation_type]
        where_clause = child_id_list.empty? ? nil : SQL.not(SQL.or(*child_id_list.map{|id|{:id=>id}}))
        where_clause = SQL.and(where_clause,assigns.constraints) unless assigns.constraints.empty?
        delete_instances_wrt_parent(relation_type,parent_id_handle,where_clause,opts)        
      end

      #TODO: make more efficient by allowing a multiple insert/update
      
      #id_handle used to pass context such as user_id and group_id
      #TODO: may collapse id_info and id_handle
      def update_from_hash_from_instance_id(id_info,id_handle,assigns,opts={})
	new_uris = Array.new
        db_rel = DB_REL_DEF[id_info[:relation_type]]
	scalar_assigns = ret_settable_scalar_assignments(assigns,db_rel)
	update_instance_from_id_info(id_info,scalar_assigns,opts)

	obj_assigns = ret_object_assignments(assigns,db_rel)
	obj_assigns.each_pair do |relation_type,child_assigns|
	  factory_uri = RestURI.ret_factory_uri(id_info[:uri],relation_type)
	  factory_id_info = IDInfoTable.get_row_from_id_handle IDHandle[:c => c, :uri => factory_uri, :is_factory => true], :raise_error => true	 
          new_uris = new_uris + update_from_hash_from_factory_id(factory_id_info,id_handle,child_assigns,opts)
        end
        new_uris
      end
    end
  end
end
