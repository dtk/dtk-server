
require 'sequel'

module XYZ
  class DB
    module DataProcessingGet

      #where clause could be hash or string
      def get_objects(relation_type,c,where_clause=nil,opts={})
	db_rel = DB_REL_DEF[relation_type]
        filter = SQL.and({CONTEXT_ID => c},where_clause)
	ds = ret_dataset_with_scalar_columns(db_rel,opts).filter(filter)
=begin
test to experiment with sequel join/graph syntax
        join_ds = ret_dataset_with_scalar_columns(DB_REL_DEF[:attribute],{:field_set => [:external_attr_ref,:component_component_id]}).from_self(:attribute)

        q = ds.from_self(:component).graph(join_ds,{:component_component_id => :id},
puts q.sql
pp [:test, q.all]
=end


	ds.all.map{|raw_hash|
          hash = process_raw_scalar_hash!(raw_hash,db_rel,c)
	  db_rel[:model_class].new(hash,c,relation_type)
        }
      end

      #TBD: convert so where clause could be hash or string
      def get_objects_wrt_parent(relation_type,parent_id_handle,where_clause=nil,opts={})
	parent_id_info = IDInfoTable.get_row_from_id_handle(parent_id_handle)
        parent_fk_col = ret_parent_id_field_name(parent_id_info[:db_rel],DB_REL_DEF[relation_type])
        get_objects(relation_type,parent_id_handle[:c],
                    SQL.and(where_clause,{parent_fk_col => parent_id_info[:id]}),
                    opts)
      end

      #TBD: convert so where clause could be hash or string       
      def get_object_ids_wrt_parent(relation_type,parent_id_handle,where_clause=nil)
	c = parent_id_handle[:c]
	db_rel = DB_REL_DEF[relation_type]
	parent_id_info = IDInfoTable.get_row_from_id_handle(parent_id_handle)
        parent_fk_col = ret_parent_id_field_name(parent_id_info[:db_rel],db_rel)
        w = SQL.and(where_clause,{parent_fk_col => parent_id_info[:id],CONTEXT_ID => c})
	ds = dataset(db_rel).select(:id).where(w)
        ds.all.map{|raw_hash|
	  IDInfoTable.ret_guid_from_db_id(raw_hash[:id],db_rel[:relation_type])
	}
      end
  

      def get_object(id_handle,opts={})
	c = id_handle[:c]
	id_info = IDInfoTable.get_row_from_id_handle id_handle, :raise_error => opts[:raise_error], :short_circuit_for_minimal_row => true
	return nil if id_info.nil? 

        return nil unless hash = get_scalar_values_given_id_info(id_info,opts)
        
        db_rel = DB_REL_DEF[id_info[:relation_type]]
        db_rel[:model_class].new(hash,c,id_info[:relation_type])
      end

      def get_parent_id_info(id_handle)
	c = id_handle[:c]
	id_info = IDInfoTable.get_row_from_id_handle id_handle
	return nil if id_info.nil? 
	return nil if id_info[:parent_id].nil?
        parent_guid = IDInfoTable.ret_guid_from_db_id(id_info[:parent_id],id_info[:parent_relation_type])
	parent_id_handle = IDHandle[:c => c, :guid => parent_guid]
        IDInfoTable.get_row_from_id_handle parent_id_handle
      end

      def get_parent_object(id_handle,opts={})
	c = id_handle[:c]
	id_info = IDInfoTable.get_row_from_id_handle id_handle,  :raise_error => opts[:raise_error]
	return nil if id_info.nil? 
	return nil if id_info[:parent_id].nil?
        parent_guid = IDInfoTable.ret_guid_from_db_id(id_info[:parent_id],id_info[:parent_relation_type])
	parent_id_handle = IDHandle[:c => c, :guid => parent_guid]
        get_object(parent_id_handle,opts)
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
	process_raw_scalar_hash!(hash,db_rel,id_info[:c],opts)
	hash
      end
       
      def ret_dataset_with_scalar_columns(db_rel,opts={})
        #if opts[:field_set] then this is taken as is as the selected columns 
        select_cols = nil
        if opts[:field_set]
          select_cols = opts[:field_set]
        else
          select_cols = (db_rel[:columns]||{}).keys 
          select_cols = db_rel[:model_class].ds_attributes(select_cols) if opts[:ds_attrs_only]        
          select_cols.concat([:id,:ref,:description,:display_name,:ref_num])
        end

	ds = dataset(db_rel).select(select_cols.shift)
	select_cols.each{|col| ds = ds.select_more(col)}
        ds
      end

      def process_raw_scalar_hash!(hash,db_rel,c,opts={})
	cols_info = db_rel[:columns]

        #process the table specfic columns
	unless cols_info.nil?
	  cols_info.each{|col,col_info|
	    if hash[col]
	      if col_info[:foreign_key_rel_type]
	        guid = IDInfoTable.ret_foreign_key_guid(hash[col],col_info[:foreign_key_rel_type])
	        if opts[:fk_as_ref].nil?
	          hash[col] = guid
	        else
	           fk_id_info = IDInfoTable.get_row_from_id_handle(
	                          IDHandle[:c => c, :guid => guid])
               
                   hash.delete(col)
                   #add a "*" form if opts[:fk_as_ref] is prefix
		   if fk_id_info[:uri] =~ Regexp.new("^#{opts[:fk_as_ref].to_s}(/.+$)")
	             rebased_uri = $1
	             hash[("*" + col.to_s).to_sym] = rebased_uri 
                   end
	        end
	      elsif col_info[:type] == :json
	        hash[col] = DB.ret_json_hash(hash[col])
	      end
	    end
	  }
	end

        #common fields
	# fill in default display name if not there
	hash[:display_name] ||= DB.ret_qualified_ref_from_scalars(hash)
	
	#fill in id unless :no_ids specified
	if opts[:no_ids]
	  hash.delete(:id)
        else
	  hash[:id] = IDInfoTable.ret_guid_from_db_id(hash[:id],db_rel[:relation_type])
        end

        [:ref, :ref_num].each{|x|hash.delete(x)}

	hash.each_pair{|col,v|hash.delete(col) if v.nil?} if opts[:no_null_cols]

	hash
      end
    end
  end
end
