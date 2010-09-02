#TODO: need to refactor to make more efficient
require 'sequel'

module XYZ
  class DB
    module DataProcessingCreate
      #creates a new instance w/ref_num bumped if needed
      #TBD: may want opt that says just create leaf nodes and error if intermediate objects do not exist	
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

     private
      def create_from_hash_with_factory(c,factory_uri,hash,clone_helper=nil,opts={})
        new_uris = Array.new
        hash.each do |ref,assignments| 
	  new_uri = create_instance(factory_uri,ref,assignments,c,clone_helper,opts)
	  Log.info("created #{new_uri}")		   
	  new_uris << new_uri
        end
	new_uris
      end

      def new_create_instance(parent_id_handle,relation_type,ref,assignments,clone_helper=nil,opts={})
        db_rel = DB_REL_DEF[relation_type]

	scalar_assignments = ret_scalar_assignments(assignments,db_rel)
	obj_assignments = ret_object_assignments(assignments,db_rel)

	#adding assignments that can be computed at this point indep. of case on parent_uri
	scalar_assignments.merge!({:ref => ref.to_s})
	old_id = scalar_assignments[:id]
	modify_to_reflect_special_processing!(scalar_assignments,db_rel,opts)

	############# processing scalar columns by inserting a row in db_rel
	new_id = nil
	parent_id = nil

        parent_id_info = IDInfoTable.get_row_from_id_handle parent_id_handle, :raise_error => opts[:raise_error], :short_circuit_for_minimal_row => true
        parent_relation_type = parent_id_info[:relation_type]
       	if parent_relation_type == :top
          ref_num = compute_ref_num(db_rel,ref,c)          	  
	  #TBD check that the assignments are legal, or trap
	  new_id = insert_into_db(c,db_rel,scalar_assignments.merge({:ref_num => ref_num}))
        else
	  parent_id = parent_id_info[:id]

	  parent_id_field = ret_parent_id_field_name(parent_id_info[:db_rel],db_rel)
          ref_num = compute_ref_num db_rel,ref,c,parent_id_field => parent_id
	  new_id = insert_into_db(c,db_rel,scalar_assignments.merge({:ref_num => ref_num,parent_id_field => parent_id_info[:id]}))
	end              

	raise Error.new("error while inserting element") if new_id.nil?
	clone_helper.update(c,db_rel,old_id,new_id,scalar_assignments) if clone_helper

	new_uri  = RestURI::ret_new_uri(factory_uri,ref,ref_num)

	#need to fill in extra columns in associated uri table entry
	IDInfoTable.update_instance(db_rel,new_id,new_uri,relation_type,parent_id,parent_relation_type)
	############# processing scalar columns by inserting a row in db_rel

	create_factory_uris_and_contained_objects(new_uri,new_id,relation_type,obj_assignments,c,clone_helper,opts)
	
	new_uri
      end

      def create_instance(factory_uri,ref,assignments,c,clone_helper=nil,opts={})
        relation_type,parent_uri = RestURI.parse_factory_uri(factory_uri) 
        db_rel = DB_REL_DEF[relation_type]

	scalar_assignments = ret_scalar_assignments(assignments,db_rel)
	obj_assignments = ret_object_assignments(assignments,db_rel)

	#adding assignments that can be computed at this point indep. of case on parent_uri
	scalar_assignments.merge!({:ref => ref.to_s})
	old_id = scalar_assignments[:id]
	modify_to_reflect_special_processing!(scalar_assignments,db_rel,opts)

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
	  new_id = insert_into_db(c,db_rel,scalar_assignments.merge({:ref_num => ref_num,parent_id_field => parent_id_info[:id]}))
	end              

	raise Error.new("error while inserting element") if new_id.nil?
	clone_helper.update(c,db_rel,old_id,new_id,scalar_assignments) if clone_helper

	new_uri  = RestURI::ret_new_uri(factory_uri,ref,ref_num)

	#need to fill in extra columns in associated uri table entry
	IDInfoTable.update_instance(db_rel,new_id,new_uri,relation_type,parent_id,parent_relation_type)
	############# processing scalar columns by inserting a row in db_rel

	create_factory_uris_and_contained_objects(new_uri,new_id,relation_type,obj_assignments,c,clone_helper,opts)
	
	new_uri
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
