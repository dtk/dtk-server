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
      #TODO: get benchmark from config file
      expose_methods_from_internal_object :db, %w{update_from_select update_from_hash_assignments update_instance get_instance_or_factory get_instance_scalar_values get_objects_just_dataset get_object_ids_wrt_parent get_parent_object exists? create_from_select create_from_hash create_simple_instance? delete_instance delete_instances_wrt_parent process_raw_db_row!} #, :benchmark => %w{create_from_hash} # :all
    end

    def model_name()
      Aux::underscore(Aux::demodulize(self.class.to_s)).to_sym
    end

    def self.model_class(model_name)
      XYZ.const_get Aux.camelize model_name
    end

    include FieldSetInstanceMixin
    extend CloneClassMixins
    extend InputIntoModelClassMixins

    #TBD: refactoring: below is old to be refactored; above is refactored
    extend ModelSchemaClassMixins
    extend ModelDataClassMixins
    include ModelDataInstanceMixins

    attr_reader :relation_type, :c

    #TODO: check why relation_type=model_name does not work
    def initialize(hash_scalar_values,c,relation_type=model_name())
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

    def model_handle()
      ModelHandle.new(@c,@relation_type)
    end

    def self.create_from_rows(model_handle,rows,opts={})
      opts = opts[:convert] ? {:convert_for_create => true} : {}
      select_ds = SQL::ArrayDataset.create(db,rows,model_handle,opts)
      override_attrs = {}
      create_opts = {} #TODO: stub
      field_set = FieldSet.new(model_handle[:model_name],rows.first.keys)
      create_from_select(model_handle,field_set,select_ds,override_attrs,create_opts)
    end

    def self.get_objects_from_search_object(search_object)
      dataset = search_object.create_dataset
      model_handle = dataset.model_handle()
      model_name = model_handle[:model_name]

      base_field_set = search_object.field_set()
      field_set = base_field_set.with_related_local_columns()
      related_col_info = base_field_set.related_remote_column_info()

      ret = nil
pp [:wo_related_col,dataset.ppsql]

      unless related_col_info
        ret = dataset.all
      else
        opts = {} #TODO: stub
        ls_opts = opts.merge(FieldSet.opt(field_set))
        graph_ds = dataset.from_self(:alias => model_handle[:model_name])
        related_col_info.each do |join_info|
          rs_opts = (join_info[:cols] ? FieldSet.opt(join_info[:cols],join_info[:model_name]) : {}).merge :return_as_hash => true
          right_ds = @db.get_objects_just_dataset(model_handle.createMH(:model_name => join_info[:model_name]),nil,rs_opts)
          graph_ds = graph_ds.graph(:left_outer,right_ds,join_info[:join_cond])
        end
        graph_ds = graph_ds.paging_and_order(opts)
        ret = graph_ds.all
      end
      ret
    end


    def self.get_display_name(id_handle)
      id = id_handle.get_id()
      return nil unless id
      obj = @db.get_objects_scalar_columns(id_handle.createMH,{:id => id}, FieldSet.opt([:display_name],id_handle[:model_name])).first
      (obj||{})[:display_name]
    end


    #TODO: deprecate or write in terms of get_objects_from_search_object
    #may do so by having constructor for search object that takes model_handle and filter
    def self.get_objects(model_handle,where_clause={},opts={})
      c = model_handle[:c]
      model_name = model_handle[:model_name]

      base_field_set =  opts[:field_set] || FieldSet.default(model_name)
      field_set = opts[:field_set] ? base_field_set.with_related_local_columns() : base_field_set
      related_col_info = base_field_set.related_remote_column_info()

      ret = nil
      unless related_col_info
        ret = @db.get_objects_scalar_columns(model_handle,where_clause,opts)
      else
        ls_opts = opts.merge(FieldSet.opt(field_set))
        graph_ds = get_objects_just_dataset(model_handle,where_clause,ls_opts)
        related_col_info.each do |join_info|
          rs_opts = (join_info[:cols] ? FieldSet.opt(join_info[:cols],join_info[:model_name]) : {}).merge :return_as_hash => true
          right_ds = @db.get_objects_just_dataset(ModelHandle.new(c,join_info[:model_name]),nil,rs_opts)
          graph_ds = graph_ds.graph(:left_outer,right_ds,join_info[:join_cond])
        end
        graph_ds = graph_ds.paging_and_order(opts)
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
      real_hash = super(x) 
      return real_hash if real_hash 
      vc_info = ret_info_if_is_virtual_column(x)
      if vc_info
        #first check if it has an explicit path or possible parents defined; otherwise look for fn
        return nested_value(*vc_info[:path]) if vc_info[:path]
        return ret_parent_name(vc_info[:possible_parents]) if vc_info[:possible_parents] and x == :parent_name
        send(x) 
      else
        nil
      end
    end

    def ret_info_if_is_virtual_column(col)
      (self.class.db_rel[:virtual_columns]||{})[col]
    end

    def ret_parent_name(possible_parents)
      #one complication is if parent is same type as self then looking for "p2", rather than p; this is due
      #to how we got around problem of having unique table names when joining table to itself
      #TODO: is it better to see if can change the joining to not have teh "2" suffix
      possible_parents.each do |p|
        parent_obj = self[relation_type == p ? "#{p}2".to_sym : p]
        return "#{p}/#{parent_obj[:display_name]}" if parent_obj and parent_obj[:display_name]
      end
      nil
    end

    #inherited virtual coulmn defs
    def parent_id()
      return id_handle()[:guid] if id_handle() and id_handle()[:guid] #short circuit 
      id_handle().get_parent_id_info()[:id]
    end

    def parent_path()
      return id_handle()[:uri] if id_handle() and id_handle()[:uri] #short circuit 
      id_handle().get_parent_id_info()[:uri]
    end
  end

  class RefObjectPairs < HashObject
  end
end

