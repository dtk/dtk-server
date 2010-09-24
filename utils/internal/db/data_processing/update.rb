
require 'sequel'

module XYZ
  class DB
    module DataProcessingUpdate
      #TODO Enable short circuit that conditionally avoids IDInfoTable
      #returns list of created uris
      def update_from_hash_assignments(id_handle,hash_assigns,opts={})
	id_info = IDInfoTable.get_row_from_id_handle id_handle, :raise_error => true 
	return update_from_hash_from_factory_id(id_info,hash_assigns,opts) if id_info[:is_factory]
        update_from_hash_from_instance_id(id_info,hash_assigns,opts)
      end

      #TDOD may remove below two public methods and subsume by above
      def update_instance(id_handle,scalar_assigns,opts={}) 
	id_info = IDInfoTable.get_row_from_id_handle id_handle, :raise_error => true
	update_instance_from_id_info(id_info,scalar_assigns,opts)
      end
    
      def update(relation_type,c,scalar_assigns,where_clause={})
	db_rel = DB_REL_DEF[relation_type]
	ds = dataset(db_rel).where(SQL.and(where_clause,{CONTEXT_ID => c}))
	#TBD: check that valid assigns
	modify_to_reflect_special_processing!(scalar_assigns,db_rel)
	ds.update(scalar_assigns)
      end
     private

      def update_instance_from_id_info(id_info,scalar_assigns,opts={})
	return nil if scalar_assigns.empty?
	db_rel = DB_REL_DEF[id_info[:relation_type]]
	ds = dataset(db_rel).where(:id => id_info[:id])
	#TBD: check that valid assigns
	modify_to_reflect_special_processing!(scalar_assigns,db_rel,opts)
	ds.update(scalar_assigns)
      end

      def update_from_hash_from_factory_id(factory_id_info,assigns,opts={})
        new_uris = Array.new
        delete_not_matching = (assigns.kind_of?(HashObject) and assigns.is_complete?)
	c = factory_id_info[:c]
        child_id_list = Array.new
	#each assigns key should be qualified ref wrt factory_id
        assigns.each_pair do |qualified_ref,child_assigns|
	  child_uri = RestURI.ret_child_uri_from_qualified_ref(factory_id_info[:uri],qualified_ref)
	  child_id_info = IDInfoTable.get_row_from_id_handle IDHandle[:c => c, :uri => child_uri]
          if child_id_info
	    update_from_hash_from_instance_id(child_id_info,child_assigns,opts)
            child_id_list << child_id_info[:id] if delete_not_matching
          else
            unless assigns.kind_of?(HashObject) and assigns.do_not_extend
              factory_id_handle = IDHandle[:c => c, :uri => factory_id_info[:uri]] 
              new_uris = new_uris + create_from_hash(factory_id_handle,{qualified_ref => child_assigns})
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

      def update_from_hash_from_instance_id(id_info,assigns,opts={})
	new_uris = Array.new
        db_rel = DB_REL_DEF[id_info[:relation_type]]
	scalar_assigns = ret_scalar_assignments(assigns,db_rel)
	update_instance_from_id_info(id_info,scalar_assigns,opts)

	obj_assigns = ret_object_assignments(assigns,db_rel)
	obj_assigns.each_pair do |relation_type,child_assigns|
	  factory_uri = RestURI.ret_factory_uri(id_info[:uri],relation_type)
	  factory_id_info = IDInfoTable.get_row_from_id_handle IDHandle[:c => c, :uri => factory_uri], :raise_error => true	 
          new_uris = new_uris + update_from_hash_from_factory_id(factory_id_info,child_assigns,opts)
        end
        new_uris
      end
    end
  end
end
