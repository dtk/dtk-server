#TODO: should probably just rename this to model.r8.rb and move directly into system folder

#TODO: lose all of these, lose notion of schema and data

require File.expand_path(UTILS_DIR+'/internal/model/schema', File.dirname(__FILE__))
require File.expand_path(UTILS_DIR+'/internal/model/input_into_model', File.dirname(__FILE__))
require File.expand_path(UTILS_DIR+'/internal/model/clone', File.dirname(__FILE__))
require File.expand_path(UTILS_DIR+'/internal/model/data', File.dirname(__FILE__))

module XYZ
  class Model < HashObject 
    class << self
    attr_reader :db

      expose_methods_from_internal_object :db, %w{update_from_hash_assignments update_instance get_instance_or_factory get_instance_scalar_values get_objects get_objects_just_dataset get_object_ids_wrt_parent get_object get_parent_object get_parent_id_info exists? create_from_hash create_simple_instance? delete_instance delete_instances_wrt_parent process_raw_db_row!}

      #TODO: put these in if needed get_instance_or_factory get_instance_scalar_values
    end
    #TBD: refactoring: below is old to be refactored; above is refactored
    extend ModelSchema
    extend ModelDataClassMixins
    extend CloneClassMixins
    extend InputIntoModelClassMixins
    include ModelDataInstanceMixins

    attr_reader :relation_type, :c

    def initialize(hash_scalar_values,c,relation_type)
      return nil if hash_scalar_values.nil?

      super(hash_scalar_values)
      @c = c
      @relation_type = relation_type
      @id_handle = 
        if hash_scalar_values[:id]
          ret_id_handle_from_db_id(hash_scalar_values[:id],relation_type)
        elsif hash_scalar_values[:uri]
          IDHandle[:c =>c, :uri => hash_scalar_values[:uri]]
        else
          nil
        end
    end

    def [](x)
      return send(x) if self.class.is_virtual_column?(x)
      super(x)
    end

    #inherited virtual coulmn defs
    def parent_id()
      return id_handle()[:guid] if id_handle() and id_handle()[:guid] #short circuit 
      get_parent_id_info()[:id]
    end

    def parent_path()
      return id_handle()[:uri] if id_handle() and id_handle()[:uri] #short circuit 
      get_parent_id_info()[:uri]
    end

  end

  class RefObjectPairs < HashObject
  end
end

