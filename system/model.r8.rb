#TODO: should probably just rename this to model.r8.rb and move directly into system folder


require File.expand_path(UTILS_DIR+'/internal/model/field_set', File.dirname(__FILE__))
require File.expand_path(UTILS_DIR+'/internal/model/input_into_model', File.dirname(__FILE__))
require File.expand_path(UTILS_DIR+'/internal/model/clone', File.dirname(__FILE__))

#TODO: lose all of these, lose notion of schema and data
require File.expand_path(UTILS_DIR+'/internal/model/schema', File.dirname(__FILE__))
require File.expand_path(UTILS_DIR+'/internal/model/data', File.dirname(__FILE__))

module XYZ
  class Model < HashObject 
    class << self
      attr_reader :db
      expose_methods_from_internal_object :db, %w{update_from_hash_assignments update_instance get_instance_or_factory get_instance_scalar_values get_objects_just_dataset get_object_ids_wrt_parent get_parent_object get_parent_id_info exists? create_from_hash create_simple_instance? delete_instance delete_instances_wrt_parent process_raw_db_row!}

      def model_class(model_name)
        XYZ.const_get Aux.camelize model_name.to_s
      end
    end

    include FieldSetInstanceMixin
    extend CloneClassMixins
    extend InputIntoModelClassMixins

    #TBD: refactoring: below is old to be refactored; above is refactored
    extend ModelSchemaClassMixins
    extend ModelDataClassMixins
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


    def self.get_objects(model_handle,where_clause={},opts={})
      c = model_handle[:c]
      model_name = model_handle[:model_name]
      field_set = opts[:field_set] || FieldSet.default(model_name)
      #returns any related tables that must be joined in (by looking at virtual coumns)
      related_columns = FieldSet.related_columns(field_set,model_name)
      ret = nil
      unless related_columns
        ret = @db.get_objects_scalar_columns(model_handle,where_clause,opts)
      else
        ls_opts = opts.merge :field_set => field_set
        graph_ds = get_objects_just_dataset(model_handle,where_clause,ls_opts)
        related_columns.each do |join_info|
          rs_opts = (join_info[:cols] ? {:field_set => join_info[:cols]} : {}).merge :return_as_hash => true
          right_ds = @db.get_objects_just_dataset(ModelHandle.new(c,join_info[:model_name]),nil,rs_opts)
          graph_ds = graph_ds.graph(:left_outer,right_ds,join_info[:join_cond])
        end
        ret = graph_ds.all
      end
      ret
    end


    def self.get_object(id_handle,opts={})
      c = id_handle[:c]
      id_info = IDInfoTable.get_row_from_id_handle id_handle, :raise_error => opts[:raise_error], :short_circuit_for_minimal_row => true
      return unless id_info and id_info[:id]
      get_objects(ModelHandle.new(c,id_info[:relation_type]),{:id => id_info[:id]},opts).first
    end

    def self.get_object_deep(id_handle,opts={})
      @db.get_instance_or_factory(id_handle,nil,opts.merge({:depth => :deep, :no_hrefs => true}))
    end

    def [](x)
      vc_info = ret_info_if_is_virtual_column(x)
      if vc_info
        #first check if it has an explicit path; otherwise look for fn
        vc_info[:path] ? nested_value(*vc_info[:path]) : send(x) 
      else
        super(x)
      end
    end

    def ret_info_if_is_virtual_column(col)
      (self.class.db_rel[:virtual_columns]||{})[col]
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

