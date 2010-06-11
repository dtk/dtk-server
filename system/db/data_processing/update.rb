require 'rubygems'
require 'sequel'

module XYZ
  class DB
    module DataProcessingUpdate
      def update_instance(id_handle,scalar_assigns,opts={}) 
	id_info = IDInfoTable.get_row_from_id_handle id_handle, :raise_error => true
	update_instance_from_id_info(id_info,scalar_assigns,opts)
      end

      def update_from_hash_assignments(id_handle,hash_assigns,opts={})
	id_info = IDInfoTable.get_row_from_id_handle id_handle, :raise_error => true 
	return update_from_hash_from_factory_id(id_info,hash_assigns,opts) if id_info[:is_factory]
        update_from_hash_from_instance_id(id_info,hash_assigns,opts)
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
	nil
      end

      def update_from_hash_from_factory_id(factory_id_info,assigns,opts={})
        delete_not_matching = (assigns.kind_of?(HashObject) and assigns.is_comprehensive?)
	c = factory_id_info[:c]
        child_id_info_list = Array.new
	#each assigns key should be qualified ref wrt factory_id
        assigns.each_pair do |qualified_ref,child_assigns|
	  child_uri = RestURI.ret_child_uri_from_qualified_ref(factory_id_info[:uri],qualified_ref)
	  child_id_info = IDInfoTable.get_row_from_id_handle IDHandle[:c => c, :uri => child_uri]
          if child_id_info
	    update_from_hash_from_instance_id(child_id_info,child_assigns,opts)
            child_id_info_list << child_id_info if delete_not_matching
          else
            factory_id_handle = IDHandle[:c => c, :uri => factory_id_info[:uri]] 
            r=create_from_hash(factory_id_handle,{qualified_ref => child_assigns},opts)
            #TBD: need here to put new item on child_id_info_list
          end
	end
        delete_not_matching_children(child_id_info_list,assigns,opts) if delete_not_matching
      end

      def delete_not_matching_children(child_id_info_list,assigns,opts={})
        #TBD: not to fix; semantics of this being empty should be to delete everyting from parent -> need parent info
        return nil if child_id_info_list.empty?
        #each element in list wil have same parent, relation_type and c
        child = child_id_info_list.first
        parent_id_handle = IDHandle[:c => child[:c], :guid => child[:parent_id]]
        relation_type = child[:relation_type]
        where_clause = SQL.not(SQL.and(*child_id_info_list.map{|ch|ch[:id]}))
        where_clause = SQL.and(where_clause,assigns.constraints) unless assigns.constraints.empty?
        delete_instances_wrt_parent(relation_type,parent_id_handle,where_clause,opts)        
      end

      def update_from_hash_from_instance_id(id_info,assigns,opts={})
	db_rel = DB_REL_DEF[id_info[:relation_type]]
	scalar_assigns = ret_scalar_assignments(assigns,db_rel)
	update_instance_from_id_info(id_info,scalar_assigns,opts)

	obj_assigns = ret_object_assignments(assigns,db_rel)
	obj_assigns.each_pair{ |relation_type,child_assigns|
	  factory_uri = RestURI.ret_factory_uri(id_info[:uri],relation_type)
	  factory_id_info = IDInfoTable.get_row_from_id_handle IDHandle[:c => c, :uri => factory_uri], :raise_error => true	 
          update_from_hash_from_factory_id(factory_id_info,child_assigns,opts)
        }
      end
    end
  end
end
