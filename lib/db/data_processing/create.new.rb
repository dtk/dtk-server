# TODO: need to refactor to make more efficient
module XYZ
  class DB
    module DataProcessingCreate
      # creates a new instance w/ref_num bumped if needed
      # TODO: make more efficient by reducing or elimintaing calss to id table as well as using bulk inserts
      # TODO: may eventually deprecate this
      def create_from_hash(id_handle,hash,opts={})
        if id_handle.is_top?()
          id_handle
        end
	id_info = IDInfoTable.get_row_from_id_handle id_handle, :raise_error => true 

	#check if instance or factory
        if id_info[:is_factory]
          factory_idh = id_handle.createIDH(:uri => id_info[:uri], :is_factory => true)
	  create_from_hash_with_factory(factory_idh,hash,opts) 
        else
          hash.map{|relation_type,child_hash|
            factory_info = IDInfoTable.get_factory_id_handle(id_handle,relation_type)
            factory_idh = id_handle.createIDH(:uri => factory_info[:uri])
            create_from_hash_with_factory(factory_idh,child_hash,opts)
          }.flatten
        end
      end

      def create_from_select(model_handle,field_set,select_ds,override_attrs={},opts={})
        duplicate_refs = opts[:duplicate_refs] || :allow #other alternatives: #:no_check | :error_on_duplicate | :prune_duplicates
        columns = field_set.cols
        overrides = override_attrs.dup

        # sequel_select = select_ds.sequel_ds.ungraphed.from_self #ungraphed and from_self just to be safe
        # sequel_select = DB.update_create_info_for_user_info!(columns,sequel_select.select(*columns),overrides,model_handle)
        # todo: is last select(*columns) needed
        pre_sequel_select = select_ds.sequel_ds.ungraphed.from_self.select(*columns)
        sequel_select = DB.update_create_info_for_user_info!(columns,pre_sequel_select,overrides,model_handle)

        # TODO: is this needed?; put in this form after removing update_create_info_for_user_info! call
        # sequel_select = sequel_select.select(*columns)
        #

        # parent_id_col can be null
        parent_id_col = model_handle.parent_id_field_name()

        # DB.update_overrides_and_cols_for_user_info!(overrides,columns,model_handle)

        db_rel = DB_REL_DEF[model_handle[:model_name]]
        ds = dataset(db_rel)
        # modify sequel_select to reflect duplicate_refs setting
        unless duplicate_refs == :no_check
          match_cols = [:c,:ref,parent_id_col].compact
          # need special processing of ref override; need to modify match_cols and select_on_match_cols
          ref_override =  overrides.delete(:ref)
          if ref_override
            sequel_select = sequel_select.select(*((columns - [:ref])+[{ref_override => :ref}])).from_self
          end

          case duplicate_refs
           when :prune_duplicates
            sequel_select = sequel_select.join_table(:left_outer,ds,match_cols,{:table_alias => :existing}).where({:existing__c => nil})
           when :error_on_duplicate
            # TODO: not right yet
            duplicate_count = sequel_select.join_table(:inner,ds,match_cols).count
            if duplicate_count > 0
              # TODO: make this a specfic error 
              raise Error.new("found #{duplicate_count.to_s} duplicates")
            end
           when :allow
            ds_to_group = sequel_select.join_table(:inner,ds,match_cols,{:table_alias => :existing})
            max_col = SQL::ColRef.max{|o|o.coalesce(:existing__ref_num,1)}
            max_ref_num_ds = ds_to_group.group(*match_cols).select(*(match_cols+[max_col]))
            ref_num_col = {SQL::ColRef.case{[[{:max => nil},nil],:max+1]} => :ref_num}
            sequel_select = sequel_select.select(*([ref_num_col]+columns-[:ref_num])).join_table(:left_outer,max_ref_num_ds,match_cols)
            columns << :ref_num unless columns.include?(:ref_num)
          end
        end

        # process overrides
        # using has_key? to take into account nil value
        sequel_select_with_cols = sequel_select.from_self.select(*columns.map{|col|overrides.has_key?(col) ? {overrides[col] => col} : col})

        # fn tries to return ids depending on whether db adater supports returning_id
        ret = nil
        if ds.respond_to?(:insert_returning_sql)
          returning_ids = Array.new
          
          returning_sql_cols = [:id,:display_name]
          returning_sql_cols << parent_id_col.as(:parent_id) if parent_id_col
          if opts[:returning_sql_cols] 
            returning_sql_cols += opts[:returning_sql_cols] 
            returning_sql_cols.uniq!
          end

          sql = ds.insert_returning_sql(returning_sql_cols,columns,sequel_select_with_cols)
          fetch_raw_sql(sql){|row| returning_ids << row}
          IDInfoTable.update_instances(model_handle,returning_ids) unless opts[:do_not_update_info_table]
          ret = opts[:returning_sql_cols] ? 
            process_json_fields_in_returning_ids!(returning_ids,db_rel) :
            ret_id_handles_from_create_returning_ids(model_handle,returning_ids)
        else
          ds.import(columns,sequel_select_with_cols)
          # TODO: need to get ids and set 
          raise Error.new("have not implemented create_from_select when db adapter does not support insert_returning_sql  not set")
        end
        ret
      end
      private
       def process_json_fields_in_returning_ids!(returning_ids,db_rel)
         # convert any json fields
         # short circuit
         return returning_ids if returning_ids.empty?
         cols_info = db_rel[:columns]
         return returning_ids unless returning_ids.first.find{|k,v|(cols_info[k]||{})[:type] == :json}
         returning_ids.each do |row|
           row.each do |k,v|
             next unless col_info = cols_info[k]
             if col_info[:type] == :json
               row[k] = DB.ret_json_hash(v,col_info)
             end
           end 
         end
         returning_ids
       end
     public
      def ret_id_handles_from_create_returning_ids(model_handle,returning_ids)
        returning_ids.map{|row|model_handle.createIDH(:id => row[:id], :display_name => row[:display_name],:parent_guid => row[:parent_id])}
      end

      def create_simple_instance?(uri_id_handle,opts={})
        return uri_id_handle[:uri] if exists? uri_id_handle
        ref,factory_uri = RestURI.parse_instance_uri(uri_id_handle[:uri])

        # create parent if does not exists and this is recursive create
        if opts[:recursive_create]
          relation_type,parent_uri = RestURI.parse_factory_uri(factory_uri)
          parent_idh = uri_id_handle.createIDH(:uri => parent_uri)
          create_simple_instance?(parent_idh,opts) unless parent_uri == "/" or exists? parent_idh
        end
        assignments = opts[:set_display_name] ? {:display_name => ref} : {}
        factory_idh = uri_id_handle.createIDH(:uri => factory_uri, :is_factory => true)
        create_from_hash(factory_idh,{ref => assignments}).first
      end

     private
      def create_from_hash_with_factory(factory_idh,hash,opts={})
        ret = Array.new
        hash.each do |ref,assignments| 
      	  new_item = create_instance(factory_idh,ref,assignments,opts)
      	  Log.info("created new object: uri=#{new_item[:uri]}; id=#{new_item[:id]}")		   
      	  ret << new_item
        end

	      ret
      end

      def create_instance(factory_idh,ref,assignments,opts={})
        relation_type,parent_uri = RestURI.parse_factory_uri(factory_idh[:uri])
        db_rel = DB_REL_DEF[relation_type]

      	scalar_assignments = ret_settable_scalar_assignments(assignments,db_rel)
      	obj_assignments = ret_object_assignments(assignments,db_rel)

      	#adding assignments that can be computed at this point indep. of case on parent_uri
      	scalar_assignments.merge!({:ref => ref.to_s})
      	old_id = scalar_assignments[:id]
      	modify_to_reflect_special_processing!(scalar_assignments,db_rel,:insert,opts)

      	############# processing scalar columns by inserting a row in db_rel
      	new_id = nil
      	parent_id = nil
      	parent_relation_type = nil
        c = factory_idh[:c]
        if parent_uri == "/" ## if top level object
          ref_num = compute_ref_num(db_rel,ref,c)          	  
      	  #TBD check that the assignments are legal, or trap
      	  new_id = insert_into_db(factory_idh,db_rel,scalar_assignments.merge({:ref_num => ref_num}))
        else
      	  parent_id_info = IDInfoTable.get_row_from_uri parent_uri,c,:raise_error => true 
      	  parent_id = parent_id_info[:id]
      	  parent_relation_type = parent_id_info[:relation_type]

      	  parent_id_field = ret_parent_id_field_name(parent_id_info[:db_rel],db_rel)
          ref_num = compute_ref_num db_rel,ref,c,parent_id_field => parent_id

          merge_attrs = {:ref_num => ref_num,parent_id_field => parent_id_info[:id]}
          # TODO: may fold into  modify_to_reflect_special_processing!, but that require sref_num be computed before this call
          if opts[:sync_display_name_with_ref] and ref_num and ref_num > 1
            merge_attrs.merge!(:display_name => "#{ref}-#{ref_num.to_s}")
          end
      	  new_id = insert_into_db(factory_idh,db_rel,scalar_assignments.merge(merge_attrs))
        end              

	raise Error.new("error while inserting element") if new_id.nil?

	new_uri  = RestURI::ret_new_uri(factory_idh[:uri],ref,ref_num)

	#need to fill in extra columns in associated uri table entry
	IDInfoTable.update_instance(db_rel,new_id,new_uri,relation_type,parent_id,parent_relation_type)
	############# processing scalar columns by inserting a row in db_rel
        container_idh = factory_idh.createIDH(:uri => new_uri, :c => c, :model_name => relation_type)
	create_factory_uris_and_contained_objects(container_idh,new_id,obj_assignments,opts)
	
	{:uri => new_uri, :id => new_id}
      end

      def create_factory_uris_and_contained_objects(container_idh,id,obj_assignments,opts={})
	db_rel = DB_REL_DEF[container_idh[:model_name]]
	return nil if db_rel.nil? #TBD: this probably should be an error
	child_list = db_rel[:one_to_many]
	return nil if child_list.nil?

	child_list.each do |child_type|
	  factory_uri = RestURI.ret_factory_uri(container_idh[:uri],child_type)
	  IDInfoTable.insert_factory(child_type,factory_uri,container_idh[:model_name],id,container_idh[:c])
	  #TBD: does not check if there are erroneous subobjects on obj_assignments
	  #index can be string or symbol
	  child_hash_or_array = obj_assignments[child_type] || obj_assignments[child_type.to_s]
	  next if child_hash_or_array.nil?
          if child_hash_or_array.kind_of?(Hash)
	    child_hash_or_array.each do |ref,assignments|
              factory_idh = container_idh.createIDH(:uri => factory_uri,:is_factory => true)
	      create_instance(factory_idh,ref,assignments,opts)
	    end
	  elsif child_hash_or_array.kind_of?(Array)
            child_hash_or_array.each do |child_hash|
	      child_hash.each do |ref,assignments|
                factory_idh = container_idh.createIDH(:uri => factory_uri,:is_factory => true)
	        create_instance(factory_idh,ref,assignments,opts)
              end
            end
	  end
	end
	nil
      end

      def compute_ref_num(db_rel,ref,c,constraints={})
	ds =  dataset(db_rel).where(SQL.and(constraints,{:ref => ref.to_s, CONTEXT_ID => c}))
     	return nil if ds.empty?()
	max = ds.max(:ref_num)
	## empty means that only one exists so return 2; otherwise return max+1
	max ? max + 1 : 2
      end

      def insert_into_db(factory_idh,db_rel,scalar_assignments)
	dataset(db_rel).insert(DB.add_assignments_for_user_info(scalar_assignments,factory_idh))
      end
    end
  end
end
