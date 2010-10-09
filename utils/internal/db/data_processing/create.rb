#TODO: need to refactor to make more efficient
require 'sequel'

module XYZ
  class DB
    module DataProcessingCreate
      #creates a new instance w/ref_num bumped if needed
      #TODO: make more efficient by reducing or elimintaing calss to id table as well as using bulk inserts
      def create_from_hash(id_handle,hash,clone_helper=nil,opts={})
	id_info = IDInfoTable.get_row_from_id_handle id_handle, :raise_error => true 

	#check if instance or factory
        if id_info[:is_factory]
	  create_from_hash_with_factory(id_info[:c],id_info[:uri],hash,clone_helper,opts) 
        else
          hash.map{|relation_type,child_hash|
            factory_id_handle = IDInfoTable.get_factory_id_handle(id_handle,relation_type)
            create_from_hash_with_factory(factory_id_handle[:c],factory_id_handle[:uri],child_hash,clone_helper,opts)
          }.flatten
        end
      end

      def create_from_select(model_handle,field_set,select,opts={})
        columns = field_set.cols
        sequel_select = select.sequel_ds
        unless columns.include?(:c)
          columns << :c
          sequel_select = sequel_select.select_more(model_handle[:c])
        end
        db_rel = DB_REL_DEF[model_handle[:model_name]]
        ds = dataset(db_rel)

        #fn tries to return ids depending on whether db adater supports returning_id
        parent_id_field_name = model_handle.parent_id_field_name()
        if ds.respond_to?(:insert_returning_sql) and parent_id_field_name
          returning_ids = Array.new
          sql = ds.insert_returning_sql([:id,parent_id_field_name],columns,sequel_select)
          fetch_raw_sql(sql){|row| returning_ids << row}
          #TODO: stub for updating the id_table
          pp returning_ids

          returning_ids.map{|row|row[:id]}
        else
          dataset(db_rel).import(columns,sequel_select)
          #TODO: need to get ids and set 
          raise Error.new("have not implemented create_from_select when db adapter does not support insert_returning_sql or parent_id_field_name not set")
          nil
        end
      end

      def create_simple_instance?(new_uri,c,opts={})
        return new_uri if exists? IDHandle[:uri => new_uri, :c => c]
        ref,factory_uri = RestURI.parse_instance_uri(new_uri)

        #create parent if does not exists and this is recursive create
        if opts[:recursive_create]
          relation_type,parent_uri = RestURI.parse_factory_uri(factory_uri)
          create_simple_instance?(parent_uri,c,opts) unless parent_uri == "/" or exists? IDHandle[:uri => parent_uri, :c => c]
        end
        assignments = opts[:set_display_name] ? {:display_name => ref} : {}
        create_from_hash(IDHandle[:c => c, :uri => factory_uri, :is_factory => true],{ref => assignments}).first
      end

     private
      def create_from_hash_with_factory(c,factory_uri,hash,clone_helper=nil,opts={})
        ret = Array.new
        hash.each do |ref,assignments| 
	  new_item = create_instance(factory_uri,ref,assignments,c,clone_helper,opts)
	  Log.info("created new object: uri=#{new_item[:uri]}; id=#{new_item[:id]}")		   
	  ret << new_item
        end
	ret
      end
=begin
      #uses sequel import to adds a set of rows to a table
      #parent_ids, not single parent to add same think to multiple points such as what happens when cloning to node_group
actually might do this by first adding all the components, getting their ids and then adding all the attributes; need to match set of ids to 
component refs in source obj; so for components adding same thing to nodes given by ids/uris; for each need to match with new id;
can do this with a query or a return on insert

      #multiple_assignments is array of form [{:parent_relation_type => .., parent_ids => [...],{ref1 => {...}, ref2 => [...]
      def create_instances(model_handle,multiple_assignments,clone_helper=nil,opts={})
        c = model_handle[:c]
        db_rel = DB_REL_DEF[relation_type]

	scalar_assignments = ret_settable_scalar_assignments(assignments,db_rel)
	obj_assignments = ret_object_assignments(assignments,db_rel)

	#adding assignments that can be computed at this point indep. of case on parent_uri
	scalar_assignments.merge!({:ref => ref.to_s})
	old_id = scalar_assignments[:id]
	modify_to_reflect_special_processing!(scalar_assignments,db_rel,:insert,opts)

	############# processing scalar columns by inserting a row in db_rel
	new_id = nil
	parent_id = parent_id_handle.get_id()
	parent_relation_type =  parent_id_handle[:model_name]
       	if parent_relation_type == :top ## if top level object
          ref_num = compute_ref_num(db_rel,ref,c)          	  
	  #TBD check that the assignments are legal, or trap
	  new_id = insert_into_db(c,db_rel,scalar_assignments.merge({:ref_num => ref_num}))
        else
	  parent_id_field = ret_parent_id_field_name(DB_REL_DEF[parent_relation_type],db_rel)
          ref_num = compute_ref_num db_rel,ref,c,parent_id_field => parent_id

          merge_attrs = {:ref_num => ref_num,parent_id_field => parent_id_info[:id]}
          #TODO: may fold into  modify_to_reflect_special_processing!, but that require sref_num be computed before this call
          if opts[:sync_display_name_with_ref] and ref_num and ref_num > 1
            merge_attrs.merge!(:display_name => "#{ref}-#{ref_num.to_s}")
          end
	  new_id = insert_into_db(c,db_rel,scalar_assignments.merge(merge_attrs))
	end              

	raise Error.new("error while inserting element") if new_id.nil?
	clone_helper.update(c,db_rel,old_id,new_id,scalar_assignments) if clone_helper

	new_uri  = RestURI::ret_new_uri(factory_uri,ref,ref_num)

	#need to fill in extra columns in associated uri table entry
	IDInfoTable.update_instance(db_rel,new_id,new_uri,relation_type,parent_id,parent_relation_type)
	############# processing scalar columns by inserting a row in db_rel

	create_factory_uris_and_contained_objects(new_uri,new_id,relation_type,obj_assignments,c,clone_helper,opts)
	
	{:uri => new_uri, :id => new_id}
      end
=end
      def create_instance(factory_uri,ref,assignments,c,clone_helper=nil,opts={})
        relation_type,parent_uri = RestURI.parse_factory_uri(factory_uri) 
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
       	if parent_uri == "/" ## if top level object
          ref_num = compute_ref_num(db_rel,ref,c)          	  
	  #TBD check that the assignments are legal, or trap
	  new_id = insert_into_db(c,db_rel,scalar_assignments.merge({:ref_num => ref_num}))
        else
	  parent_id_info = IDInfoTable.get_row_from_uri parent_uri,c,:raise_error => true 
	  parent_id = parent_id_info[:id]
	  parent_relation_type = parent_id_info[:relation_type]

	  parent_id_field = ret_parent_id_field_name(parent_id_info[:db_rel],db_rel)
          ref_num = compute_ref_num db_rel,ref,c,parent_id_field => parent_id

          merge_attrs = {:ref_num => ref_num,parent_id_field => parent_id_info[:id]}
          #TODO: may fold into  modify_to_reflect_special_processing!, but that require sref_num be computed before this call
          if opts[:sync_display_name_with_ref] and ref_num and ref_num > 1
            merge_attrs.merge!(:display_name => "#{ref}-#{ref_num.to_s}")
          end
	  new_id = insert_into_db(c,db_rel,scalar_assignments.merge(merge_attrs))

	end              

	raise Error.new("error while inserting element") if new_id.nil?
	clone_helper.update(c,db_rel,old_id,new_id,scalar_assignments) if clone_helper

	new_uri  = RestURI::ret_new_uri(factory_uri,ref,ref_num)

	#need to fill in extra columns in associated uri table entry
	IDInfoTable.update_instance(db_rel,new_id,new_uri,relation_type,parent_id,parent_relation_type)
	############# processing scalar columns by inserting a row in db_rel

	create_factory_uris_and_contained_objects(new_uri,new_id,relation_type,obj_assignments,c,clone_helper,opts)
	
	{:uri => new_uri, :id => new_id}
      end

      def create_factory_uris_and_contained_objects(uri,id,relation_type,obj_assignments,c,clone_helper=nil,opts={})
	db_rel = DB_REL_DEF[relation_type]
	return nil if db_rel.nil? #TBD: this probably should be an error
	child_list = db_rel[:one_to_many]
	return nil if child_list.nil?

	child_list.each{|child_type|
	  factory_uri = RestURI.ret_factory_uri(uri,child_type)
	  IDInfoTable.insert_factory(child_type,factory_uri,relation_type,id,c)
	  #TBD: does not check if there are erroneous subobjects on obj_assignments
	  #index can be string or symbol
	  child_hash_or_array = obj_assignments[child_type] || obj_assignments[child_type.to_s]
	  next if child_hash_or_array.nil?
          if child_hash_or_array.kind_of?(Hash)
	    child_hash_or_array.each{|ref,assignments|
	      create_instance(factory_uri,ref,assignments,c,clone_helper,opts)
	    }
	  elsif child_hash_or_array.kind_of?(Array)
            child_hash_or_array.each{|child_hash|
	      child_hash.each{|ref,assignments|
	        create_instance(factory_uri,ref,assignments,c,clone_helper,opts)
              }
            }
	  end
	}
	nil
      end

      def compute_ref_num(db_rel,ref,c,constraints={})
	ds =  dataset(db_rel).where(SQL.and(constraints,{:ref => ref.to_s, CONTEXT_ID => c}))
     	return nil if ds.empty?()
	max = ds.max(:ref_num)
	## empty means that only one exists so return 2; otherwise return max+1
	max ? max + 1 : 2
      end

      def insert_into_db(c,db_rel,scalar_assignments)
	new_id = dataset(db_rel).insert(scalar_assignments.merge({CONTEXT_ID => c}))
	raise Error.new("Error inserting into table") unless new_id
        new_id
      end
    end
  end
end
