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
      expose_methods_from_internal_object :db, %w{update_from_select update_from_hash_assignments update_instance get_instance_or_factory get_instance_scalar_values get_objects_just_dataset get_object_ids_wrt_parent get_parent_object exists? create_from_select ret_id_handles_from_create_returning_ids create_from_hash create_simple_instance? delete_instance delete_instances_wrt_parent process_raw_db_row!} #, :benchmark => %w{create_from_hash} # :all
    end

    def self.model_name()
      Aux::underscore(Aux::demodulize(self.to_s)).to_sym
    end
    def model_name()
      self.class.model_name()
    end

    def self.model_class(model_name)
      XYZ.const_get Aux.camelize model_name
    end

    module Delim
      Char = "_"
      Common = "#{Char}#{Char}"
      NumericIndex = Char
      DisplayName = Common
      RegexpCommon = Regexp.new(Common)
      NumericIndexRegexp = Regexp.new("#{Common}#{NumericIndex}([0-9]+)")
    end

    include FieldSetInstanceMixin
    extend CloneClassMixins
    extend InputIntoModelClassMixins

    #TBD: refactoring: below is old to be refactored; above is refactored
    extend ModelSchemaClassMixins
    extend ModelDataClassMixins
    include ModelDataInstanceMixins

    attr_reader :relation_type, :id_handle, :c

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

    def id()
      id_handle ? id_handle.get_id() : nil
    end

    def set_id_handle(hash)
      @id_handle = IDHandle[hash]
    end

    def model_handle()
      ModelHandle.new(@c,@relation_type)
    end

    def self.update_from_rows(model_handle,rows,opts={})
      return nil if rows.empty?
      array_ds = SQL::ArrayDataset.create(db,rows,model_handle,opts.merge(:convert_for_update=>true))
      field_set = Model::FieldSet.new(model_handle[:model_name],rows.first.keys - [:id])
      update_from_select(model_handle,field_set,array_ds)
    end

    def update(scalar_assignments,opts={})
      scalar_assignments.each{|k,v| self[k] = v}
      raise Error.new("Cannot execute update without the object having an id") unless id()
      self.class.update_from_rows(model_handle,[scalar_assignments.merge(:id => id())],opts)
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
      dataset = search_object.create_dataset()
      dataset ? dataset.all : nil
    end

    def get_children_from_search_pattern_hash(child_model_name,search_pattern_hash_x)
      parent_col_clause = [[:eq, DB.parent_field(model_name,child_model_name),id()]]
      filter_x =  search_pattern_hash_x[:filter]
      filter =
        if filter_x.nil?
          [:and] + parent_col_clause
        elsif filter_x.first == :and
          filter_x + parent_col_clause
        else
          [:and] + filter_x + parent_col_clause
        end 
      search_pattern_hash = {
        :filter => filter,
        :columns => search_pattern_hash_x[:columns]
      }
      child_model_handle = model_handle.createMH(child_model_name)
      Model.get_objects_from_search_pattern_hash(child_model_handle,search_pattern_hash)
    end

    def self.get_objects_from_search_pattern_hash(model_handle,search_pattern_hash)
      model_name = model_handle[:model_name]
      hash = search_pattern_hash.merge(:relation => model_name)
      search_object = SearchObject.create_from_input_hash({"search_pattern" => hash},model_name,model_handle[:c])
      Model.get_objects_from_search_object(search_object)
    end

    def self.get_object_columns(id_handle,columns)
      search_pattern_hash = {
        :relation => id_handle[:model_name],
        :filter => [:and,[:eq, :id, id_handle.get_id()]],
        :columns => columns
      }
      get_objects_from_search_pattern_hash(id_handle.createMH(),search_pattern_hash).first
    end

    #may deprecate below
    def self.get_display_name(id_handle)
      id = id_handle ? id_handle.get_id() : nil
      return nil unless id
      obj = @db.get_objects_scalar_columns(id_handle.createMH,{:id => id}, FieldSet.opt([:display_name],id_handle[:model_name])).first
      (obj||{})[:display_name]
    end


    #TODO: deprecate or write in terms of get_objects_from_search_object
    #may do so by having constructor for search object that takes model_handle and filter
    #TODO: this fn is limited in how ir deals with vcols on column list;
    def self.get_objects(model_handle,where_clause={},opts={})
      c = model_handle[:c]
      model_name = model_handle[:model_name]

      base_field_set =  opts[:field_set] || FieldSet.default(model_name)
      field_set = opts[:field_set] ? base_field_set.with_related_local_columns() : base_field_set
      related_col_info = base_field_set.related_remote_column_info()

      ret = nil
      augmented_opts = opts.merge(FieldSet.opt(field_set))
      unless related_col_info
        ret = @db.get_objects_scalar_columns(model_handle,where_clause,augmented_opts)
      else
        graph_ds = get_objects_just_dataset(model_handle,where_clause,augmented_opts)
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
      #TODO: make more efficient by calling Hash::[] rather than HashObject::[]
      return super(x) if has_key?(x)
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

    def self.materialize_virtual_columns!(rows,virtual_cols)
      rows.each do |r|
        virtual_cols.each{|vc|r[vc] = r[vc]}
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
   protected


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

