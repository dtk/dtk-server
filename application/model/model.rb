
#################
#TBD: will seperate into seperate files
#TBD: looks like much shared on relationship between Library, Project, and Deployment (they are all containers; so might refactor as one object that has type)

module XYZ
  module ClassMixinDataSourceExtensions
    @@ds_class_objects ||= Hash.new
    def provider_class_object(provider_type)
      @@ds_class_objects[self] ||= Hash.new
      return @@ds_class_objects[self][provider_type] if @@ds_class_objects[self][provider_type]
      obj_class = Aux.demodulize(self.to_s)
      obj_type = Aux.underscore(obj_class)
      require File.expand_path("#{obj_type}/#{provider_type}_#{obj_type}", File.dirname(__FILE__))
      base_class = DSAdapter.const_get provider_type.to_s.capitalize
      @@ds_class_objects[self][provider_type] = base_class.const_get obj_class
    end
  end

  #TBD: re-examine whether current scheme is best way to implement relationship between model top, specfic model classes and the XYZ::model utility class
  class Object < Model
    extend ImportObject
    extend ExportObject
    set_relation_as_top()
    class << self
      #### Actions
      #idempotent
      def delete(id_handle,opts={})
        delete_instance(id_handle,opts)if exists? id_handle
      end
      #idempotent
      def create_simple(new_uri,c,opts={})
        create_simple_instance?(new_uri,c,opts)
      end

      #idempotent
      def update_from_hash(id_handle,hash,opts)
	# Aux.ret_hash_assignments makes sure all hash keys are symbols
        hash_assigns = Aux.ret_hash_assignments(hash)
        update_from_hash_assignments(id_handle,hash_assigns,opts)
      end
  

      #not idempotent
      def clone(id_handle,target_id_handle,relation_type,clone_helper=nil,opts={})
        clone_helper = CloneHelper.new(@db) if no_clone_helper_provided = clone_helper.nil?

	obj = get_instance_or_factory(id_handle,nil,{:depth => :deep, :no_hrefs => true})
	             
        raise Error.new("clone source (#{id_handle}) not found") if obj.nil? 

        tgt_factory_id_handle = get_factory_id_handle(target_id_handle,relation_type)
	raise Error.new("clone target (#{target_id_handle}) not found") if tgt_factory_id_handle.nil?
	new_uris = create_from_hash(tgt_factory_id_handle,obj, clone_helper,opts.merge({:shift_id_to_ancestor => true}))
	clone_helper.set_foreign_keys_to_right_values() if no_clone_helper_provided
        new_uris
      end

      def get_contained_attribute_ids(id_handle,opts={})
	cmps = get_objects_wrt_parent(:component,id_handle)
	nodes = get_objects_wrt_parent(:node,id_handle)
        (cmps||[]).map{|cmp|cmp.get_contained_attribute_ids(opts)}.flatten() +
        (nodes||[]).map{|node|node.get_contained_attribute_ids(opts)}.flatten()
      end

      #type can be :asserted, :derived or :value
      def get_contained_attributes(type,id_handle,opts={})
	ret = {}
	cmps = get_objects_wrt_parent(:component,id_handle)
	cmps.each{|cmp|
	  values = cmp.get_contained_attribute_values(type,opts)
	  if values
	    ret[:component]||= {}
	    ret[:component][cmp.get_qualified_ref.to_sym] = values 
          end
        }
	nodes = get_objects_wrt_parent(:node,id_handle)
	nodes.each{|node|
	  values = node.get_direct_attribute_values(type,opts)
	  if values
	    ret[:node]||= {}
	    ret[:node][node.get_qualified_ref.to_sym] = values 
          end
        }
        ret
      end

      #TBD: temp
      def get_guid(id_handle)
        id_info = IDInfoTable.get_row_from_id_handle(id_handle) 
        {:guid => IDInfoTable.ret_guid_from_id_info(id_info)}
      end
    end
  end
end



