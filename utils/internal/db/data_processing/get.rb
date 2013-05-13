module XYZ
  class DB
    module DataProcessingGet
      def execute_function(fn_name,model_handle,*args)
        execute_function_aux(fn_name,model_handle[:c],*args)
      end

      #where clause could be hash or string
      def get_objects_scalar_columns(model_handle,where_clause=nil,opts={})
        model_name =  model_handle[:model_name]
        #special processing if parent_id given
        parent_id = opts[:parent_id]
        if parent_id
          parent_id_info = IDInfoTable.get_row_from_guid(parent_id)
          parent_fk_col = ret_parent_id_field_name(parent_id_info[:db_rel],DB_REL_DEF[model_name])
          where_clause = SQL.and(where_clause,{parent_fk_col => parent_id_info[:id]})
        end

        db_rel = DB_REL_DEF[model_name]
        filter = DB.augment_for_authorization(where_clause,model_handle) #SQL.and({CONTEXT_ID => c},where_clause)
	ds = ret_dataset_with_scalar_columns(db_rel,opts).filter(filter)
        return SQL::Dataset.new(model_handle,ds.from_self(:alias => model_name)) if opts[:return_just_sequel_dataset]

        ds = DB.ret_paging_and_order_added_to_dataset(ds,opts)
	ds.all.map do |raw_hash|
          hash = process_raw_scalar_hash!(raw_hash,db_rel)
          db_rel[:model_class].create_from_model_handle(hash,model_handle)
        end
      end

      def get_objects_just_dataset(model_handle,where_clause=nil,opts={})
        get_objects_scalar_columns(model_handle,where_clause,opts.merge({:return_just_sequel_dataset => true}))
      end


      #TODO: may be able to optimze seeing that curerntly uses get_objects
      def get_object_scalar_columns(id_handle,opts={})
	id_info = IDInfoTable.get_row_from_id_handle id_handle, :raise_error => opts[:raise_error], :short_circuit_for_minimal_row => true
	return unless id_info and id_info[:id]
        get_objects_scalar_columns(id_handle.createMH(id_info[:relation_type]),{:id => id_info[:id]},opts).first
      end

      #TBD: convert so where clause could be hash or string       
      def get_object_ids_wrt_parent(relation_type,parent_id_handle,where_clause=nil)
	db_rel = DB_REL_DEF[relation_type]
	parent_id_info = IDInfoTable.get_row_from_id_handle(parent_id_handle)
        parent_fk_col = ret_parent_id_field_name(parent_id_info[:db_rel],db_rel)
        wc = SQL.and(where_clause,{parent_fk_col => parent_id_info[:id]})
	ds = dataset(db_rel).select(:id).where(DB.augment_for_authorization(wc,model_handle))
        ds.all.map{|raw_hash|
	  IDInfoTable.ret_guid_from_db_id(raw_hash[:id],db_rel[:relation_type])
	}
      end

      def process_raw_db_row!(row,model_name,opts={})
        relation_type = model_name
        return row unless relation_type and DB_REL_DEF[relation_type]
        process_raw_scalar_hash!(row,DB_REL_DEF[relation_type],opts)
      end

      def get_parent_object(id_handle,opts={})
	      parent_id_handle = id_handle.get_parent_id_handle()
        get_object_scalar_columns(parent_id_handle,opts)
      end


      #if uri is given, it is relative to href_prefix
      # TBD: may put href_prefix in opts or possible just provide one hash arg 'params'
      def get_instance_or_factory(id_handle,href_prefix=nil,opts_x={}) 
	opts = href_prefix.nil? ? opts_x.merge({:no_hrefs=>true}) : opts_x 

	id_info = IDInfoTable.get_row_from_id_handle id_handle,  :raise_error => true 

	#check if instance or factory
	return get_factory(href_prefix,id_info,opts) if id_info[:is_factory]
	get_instance(href_prefix,id_info,true,opts)
      end

      #TBD: remove form where return {x => y}; just return y
      def get_instance_scalar_values(id_handle,opts={})
	id_info = IDInfoTable.get_row_from_id_handle id_handle,  :raise_error => opts[:raise_error]
	return nil if id_info.nil? 
	hash = get_scalar_values_given_id_info(id_info,opts)
	{id_info.ret_qualified_ref() => hash}
      end

      def exists?(id_handle)
        return true if id_handle.is_top?
        IDInfoTable.get_row_from_id_handle(id_handle) ? true : nil
      end

     private

      #returns factory and additionally children if in opts {:depth == :deep)
      #TBD: should get_factory (like get_instance wrap everything in top level element?
      def get_factory(href_prefix,factory_id_info,opts={}) 
        hash = opts[:no_hrefs] ? {} : RestContent.ret_link(:self,factory_id_info[:uri],href_prefix) 
	hash[:display_name] = "Factory for #{factory_id_info[:relation_type]}" unless opts[:no_hrefs]
        children_id_infos = IDInfoTable.get_factory_children_rows(factory_id_info)
	return opts[:object_form] ? RefObjectPairs.new(hash) : hash if children_id_infos.nil?
	
	#case on whether want summary for children or all their attributes
	if opts[:depth] == :deep or opts[:depth] == :scalar_detail	
	  children_id_infos.each do |id_info|
	    qualified_ref = id_info.ret_qualified_ref()
	    hash[qualified_ref] = get_instance(href_prefix,id_info,false,opts)
	  end
	else
  	  # get links to all children 
	  children_id_infos.each do |id_info| 
	    key,value = RestContent.ret_instance_summary(id_info,href_prefix,opts)
	    hash[key] = value
	  end
	end
	opts[:object_form] ? RefObjectPairs.new(hash) : hash
      end

      def get_instance(href_prefix,id_info,is_top_level=true,opts={})

	#get scalar values
	hash = (is_top_level and opts[:no_top_level_scalars]) ? {} : get_scalar_values_given_id_info(id_info,opts) 

        #get self link
	unless opts[:no_hrefs]
	  link = RestContent.ret_link(:self,id_info[:uri],href_prefix) 	
          link.each{|k,v|hash[k]=v}
	end
  
	#get refs to the child table objects (through getting there factories)
	if opts[:depth] != :scalar_detail 
          db_rel = DB_REL_DEF[id_info[:relation_type]]
	  child_list = db_rel[:one_to_many]
	  unless child_list.nil?
	    child_list.each do |child_type|
              next if opts[:ds_attrs_only] and not db_rel[:model_class].is_ds_subobject?(child_type)
	      factory_uri = RestURI.ret_factory_uri(id_info[:uri],child_type)
	      factory_id_info = IDInfoTable.get_row_from_uri(factory_uri,id_info[:c])

              #TODO: hack until we get rid of factory rows in id info table; this is needed because some create methods dont put in factory rows
              if factory_id_info.nil?
                IDInfoTable.insert_factory(child_type,factory_uri,id_info[:relation_type],id_info[:id],id_info[:c])
                Log.info("adding factory #{factory_uri} to id info table")
                factory_id_info = IDInfoTable.get_row_from_uri(factory_uri,id_info[:c])
              end
              ##end of hack

              next unless factory_id_info #skip if this object does not have a child of type child_type
	      factory_content = get_factory(href_prefix,factory_id_info,opts)
	      hash[child_type] = factory_content unless factory_content.empty?
	    end
	  end
	end
        if opts[:object_form]
          obj = DB_REL_DEF[id_info[:relation_type]][:model_class].new(hash,id_info[:c],id_info[:relation_type]) 
	  is_top_level ? RefObjectPairs.new({id_info.ret_qualified_ref() => obj}) : obj
         else
	  is_top_level ? {id_info.ret_qualified_ref() => hash} : hash
         end
      end

      def get_scalar_values_given_id_info(id_info,opts={})
	db_rel = DB_REL_DEF[id_info[:relation_type]]
	ds = ret_dataset_with_scalar_columns(db_rel,opts)
        hash = ds.where(:id => id_info[:id]).first
	process_raw_scalar_hash!(hash,db_rel,opts)
	hash
      end
       
      def ret_dataset_with_scalar_columns(db_rel,opts={})
        #if opts[:field_set] then this is taken as is as the selected columns 
        return dataset(db_rel) if opts[:field_set] and opts[:field_set].kind_of?(Model::FieldSetAll)

        select_cols = nil
        if opts[:field_set]
          #TODO: see if can get rid of this special case
          if db_rel[:relation_type] == :id_info
            select_cols = opts[:field_set].cols
          else
            select_cols = opts[:field_set].only_including(Model::FieldSet.all_real(db_rel[:relation_type])).cols
          end
        else
          #TODO : change below to be in terms of a FieldSet call
          select_cols = (db_rel[:columns]||{}).keys 
          select_cols = db_rel[:model_class].ds_attributes(select_cols) if opts[:ds_attrs_only]        
          select_cols.concat([:id,:ref,:description,:display_name,:ref_num])
        end

	dataset(db_rel).select(*select_cols)
      end

      #TODO!!! need to determine if this will be passed materialized virtual columns in which case we need to reformulate their types
      def process_raw_scalar_hash!(hash,db_rel,opts={})
	cols_info = db_rel[:columns]
        #process the table specific columns
	if cols_info
          hash.each_key do |col|
            next if hash[col].nil?
            col_info = cols_info[col]
            next unless col_info 
            if col_info[:foreign_key_rel_type]
              guid = IDInfoTable.ret_foreign_key_guid(hash[col],col_info[:foreign_key_rel_type])
              if opts[:fk_as_ref].nil?
                hash[col] = guid
              else
                fk_id_info = IDInfoTable.get_row_from_guid(guid)               
                hash.delete(col)
                #add a "*" form if opts[:fk_as_ref] is prefix
                if opts[:fk_as_ref] == "/"
                  hash[("*" + col.to_s).to_sym] = fk_id_info[:uri] 
                elsif fk_id_info[:uri] =~ Regexp.new("^#{opts[:fk_as_ref].to_s}(/.+$)")
                  rebased_uri = $1
                  hash[("*" + col.to_s).to_sym] = rebased_uri 
                end
              end
            elsif col_info[:type] == :json
              hash[col] = DB.ret_json_hash(hash[col],col_info,opts)
            end
          end
	end

        #common fields
	# fill in default display name if not there
        #TODO: this does not work if dont retrive :display_name but get :ret
        qualified_ref = DB.ret_qualified_ref_from_scalars(hash)
	hash[:display_name] ||= qualified_ref if qualified_ref
	
	#fill in id unless :no_ids specified
	if opts[:no_ids]
	  hash.delete(:id)
        elsif hash[:id]
	  hash[:id] = IDInfoTable.ret_guid_from_db_id(hash[:id],db_rel[:relation_type])
        end

        [:ref_num,:ref].each{|col|hash.delete(col)} unless opts[:keep_ref_cols]

	hash.each_pair{|col,v|hash.delete(col) if v.nil?} if opts[:no_null_cols]

	hash
      end
    end
  end
end
