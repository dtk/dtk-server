#TODO: model_name and relation_type redundant
require File.expand_path(UTILS_DIR+'/internal/model/field_set', File.dirname(__FILE__))
require File.expand_path(UTILS_DIR+'/internal/model/input_into_model', File.dirname(__FILE__))
require File.expand_path(UTILS_DIR+'/internal/model/clone', File.dirname(__FILE__))
require File.expand_path(UTILS_DIR+'/internal/model/get_items', File.dirname(__FILE__))

#TODO: lose all of these, lose notion of schema and data
require File.expand_path(UTILS_DIR+'/internal/model/schema', File.dirname(__FILE__))
require File.expand_path(UTILS_DIR+'/internal/model/data', File.dirname(__FILE__))

module XYZ
  class Model < HashObject 
    include R8Tpl::Utility::I18n
    extend R8Tpl::Utility::I18n
    extend ImportObject
    extend ExportObject
    class << self
      attr_reader :db
      #TODO: get benchmark from config file
      expose_methods_from_internal_object :db, %w{update_from_select update_from_hash_assignments update_instance execute_function get_instance_or_factory get_instance_scalar_values get_objects_just_dataset get_object_ids_wrt_parent get_parent_object exists? create_from_select ret_id_handles_from_create_returning_ids create_from_hash create_simple_instance? delete_instance delete_instances delete_instances_wrt_parent process_raw_db_row!} #, :benchmark => %w{create_from_hash} # :all
    end

    def self.model_name()
      model_name_x = Aux::underscore(Aux::demodulize(self.to_s)).to_sym
      SubClassRelations[model_name_x]|| model_name_x
    end
    def model_name()
      @relation_type || self.class.model_name() 
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
    include CloneInstanceMixins
    extend InputIntoModelClassMixins
    include GetItemsInstanceMixins

    #TBD: refactoring: below is old to be refactored; above is refactored
    extend ModelSchemaClassMixins
    extend ModelDataClassMixins
    include ModelDataInstanceMixins

    #this may be overwritten by the models
    def self.create(hash_scalar_values,c,relation_type_x=model_name(),id_handle=nil)
      self.new(hash_scalar_values,c,relation_type_x,id_handle)
    end
    #TODO: make initialize and use create
    #TODO: check why relation_type=model_name does not work
    def initialize(hash_scalar_values,c,relation_type_x=model_name(),id_handle=nil)
      return nil if hash_scalar_values.nil?
      super(hash_scalar_values)
      relation_type = SubClassRelations[relation_type_x]||relation_type_x
      @c = c
      @relation_type = relation_type
      @id_handle = id_handle ||
        if hash_scalar_values[:id]
          ret_id_handle_from_db_id(hash_scalar_values[:id],relation_type)
        elsif hash_scalar_values[:uri]
          IDHandle[:c =>c, :uri => hash_scalar_values[:uri]]
        else
          nil
        end
    end

    def self.create_from_model_handle(hash_scalar_values,model_handle)
      self.new(hash_scalar_values,model_handle[:c],model_handle[:model_name])
    end

    def i18n_language()
      @id_handle ? @id_handle.i18n_language() : R8::Config[:default_language]
    end

   private
    SubClassRelations = {
     :assembly => :component
    }
   public

    def self.find_subtype_model_name(id_handle)
      model_name = id_handle[:model_name]
      return model_name unless SubClassRelations.values.include?(model_name)
      #TODO: make this data driven too off SubClassRelations
      if model_name == :component
        type = get_object_scalar_column(id_handle,:type)
        type == "composite" ? :assembly : model_name
      else
        Log.error("not implemented: finding subclass of relation #{model_name}")
        model_name
      end
    end

    def subset(*keys)
      self.class.new(Aux.hash_subset(self,keys),@c,@relation_type,@id_handle)
    end
    #subset with virtual columns; tehy get substituted for real columns
    #TODO: this may be good place to materialze vcs
    def subset_with_vcs(*keys_x)
      new_field_set = Model::FieldSet.new(@relation_type,keys_x).with_replaced_local_columns?()
      keys = new_field_set ? new_field_set.cols : keys_x
      subset(*keys)
    end

    attr_reader :relation_type,:c

    #id and mode_handle related methods
    def id()
      return self[:id] if self[:id] #short cicuit
      id_handle ? id_handle.get_id() : nil
    end

    def set_id_handle(hash)
      @id_handle = IDHandle[hash]
    end

    def id_handle(hash_info=nil)
      hash_info ? @id_handle.createIDH(hash_info) : @id_handle 
    end

    def get_parent_id_handle()
      id_handle.get_parent_id_handle()
    end

    def model_handle(mn=nil)
      mh = ModelHandle.new(@c,@relation_type)
      mn ? mh.createMH(mn) : mh
    end
    #######

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

    def self.update_rows_meeting_filter(model_handle,scalar_assignments,filter_hash,opts={})
      where_clause = SQL::DataSetSearchPattern.ret_sequel_filter(filter_hash,model_handle)
      @db.update_rows_meeting_filter(model_handle,scalar_assignments,where_clause,opts)
    end

    def update_from_hash_assignments(scalar_assignments,opts={})
      self.class.update_from_hash_assignments(id_handle,scalar_assignments,opts)
    end

    def self.create_from_rows(model_handle,rows,opts={})
      select_ds = SQL::ArrayDataset.create(db,rows,model_handle,opts[:convert] ? {:convert_for_create => true} : {})
      override_attrs = {}
      create_opts = Aux::hash_subset(opts,[:returning_sql_cols])
      field_set = FieldSet.new(model_handle[:model_name],rows.first.keys)
      create_from_select(model_handle,field_set,select_ds,override_attrs,create_opts)
    end

    def self.select_process_and_update(model_handle,cols_x,id_list,opts={},&block)
      cols = cols_x.include?(:id) ? cols_x : cols_x +[:id]
      fs = Model::FieldSet.opt(cols,model_handle[:model_name])
      wc = SQL.in(:id,id_list)
      existing_rows = get_objects_just_dataset(model_handle,wc,fs).for_update().all()
      modified_rows = block.call(existing_rows)
      #TODO: should check that every id in id_list appears in modified_rows
      update_from_rows(model_handle,modified_rows)
    end


    def self.get_objects_from_search_object(search_object,opts={})
      dataset = search_object.create_dataset()
      dataset ? dataset.all(opts) : nil
    end

    def self.get_objects_from_join_array(model_handle,base_sp_hash,join_array,opts={})
      base_sp = SearchPatternSimple.new(base_sp_hash)
      dataset = SQL::DataSetSearchPattern.create_dataset_from_join_array(model_handle,base_sp,join_array)
      dataset ? dataset.all(opts) : nil
    end

    def get_children_objs(child_model_name,sp_hash_x,opts={})
      parent_col_clause = [:eq, DB.parent_field(model_name,child_model_name),id()]
      sp_hash = HashSearchPattern.add_to_filter(sp_hash_x,parent_col_clause)
      child_model_handle = model_handle.createMH(child_model_name)
      Model.get_objs(child_model_handle,sp_hash,opts)
    end
    #TODO: deprecate below
    def get_children_from_sp_hash(child_model_name,sp_hash_x,opts={})
      parent_col_clause = [:eq, DB.parent_field(model_name,child_model_name),id()]
      sp_hash = HashSearchPattern.add_to_filter(sp_hash_x,parent_col_clause)
      child_model_handle = model_handle.createMH(child_model_name)
      Model.get_objects_from_sp_hash(child_model_handle,sp_hash,opts)
    end

    def update_object!(*cols)
      cols_to_get =  cols.reject{|col|self.has_key?(col)}
      return self if cols_to_get.empty?
      opts = (cols_to_get & [:ref,:ref_num]).empty? ? {} : {:keep_ref_cols => true}
      vals = get_objects_from_sp_hash({:cols => cols_to_get},opts).first
      vals.each{|k,v|self[k]=v}
      self
    end

    def get_objs(sp_hash_x,opts={})
      sp_hash = HashSearchPattern.add_to_filter(sp_hash_x,[:eq, :id, id()])
      Model.get_objs(model_handle(),sp_hash,opts)
    end
    #TODO: remove get_objects_from_sp_hash
    def get_objects_from_sp_hash(sp_hash_x,opts={})
      sp_hash = HashSearchPattern.add_to_filter(sp_hash_x,[:eq, :id, id()])
      Model.get_objects_from_sp_hash(model_handle(),sp_hash,opts)
    end

    def get_objs_col(sp_hash_x,col=nil,opts={})
      #if col not given assumption that sp_hash_x is of form {:cols => [col]} or symbol
      if sp_hash_x.kind_of?(Symbol)
        sp_hash_x = {:cols => [sp_hash_x]}
      end
      col ||= sp_hash_x[:cols].first
      get_objs(sp_hash_x,opts).map{|r|r[col]}.compact
    end
    #TODO: removeg et_objects_col_from_sp_hash
    def get_objects_col_from_sp_hash(sp_hash_x,col=nil,opts={})
      #if col not given assumption that sp_hash_x is of form {:cols => [col]} or symbol
      if sp_hash_x.kind_of?(Symbol)
        sp_hash_x = {:cols => [sp_hash_x]}
      end
      col ||= sp_hash_x[:cols].first
      get_objects_from_sp_hash(sp_hash_x,opts).map{|r|r[col]}.compact
    end

    def self.get_objects_in_set_from_sp_hash(id_handles,sp_hash_x,opts={})
      return Array.new if id_handles.empty?
      sample_idh = id_handles.first
      model_handle = sample_idh.createMH()
      sp_hash = HashSearchPattern.add_to_filter(sp_hash_x,[:oneof, :id, id_handles.map{|idh|idh.get_id()}])
      Model.get_objects_from_sp_hash(model_handle,sp_hash,opts)
    end

    def self.get_objs(model_handle,sp_hash,opts={})
      model_name = model_handle[:model_name]
      hash = sp_hash.merge(:relation => model_name)
      search_object = SearchObject.create_from_input_hash({"search_pattern" => hash},model_name,model_handle[:c])
      Model.get_objects_from_search_object(search_object,opts)
    end
    #TODO: remove below
    def self.get_objects_from_sp_hash(model_handle,sp_hash,opts={})
      model_name = model_handle[:model_name]
      hash = sp_hash.merge(:relation => model_name)
      search_object = SearchObject.create_from_input_hash({"search_pattern" => hash},model_name,model_handle[:c])
      Model.get_objects_from_search_object(search_object,opts)
    end

    def get_object_columns(id_handle,columns)
      self.class.get_object_columns(id_handle(),columns)
    end

    def self.get_object_columns(id_handle,columns)
      sp_hash = {
        :relation => id_handle[:model_name],
        :filter => [:and,[:eq, :id, id_handle.get_id()]],
        :columns => columns
      }
      get_objects_from_sp_hash(id_handle.createMH(),sp_hash).first
    end

    def self.get_object_scalar_column(id_handle,col)
      (get_object_scalar_columns(id_handle,[col])||{})[col]
    end

    def self.get_object_scalar_columns(id_handle,cols)
      id = id_handle && id_handle.get_id() 
      return nil unless id
      @db.get_objects_scalar_columns(id_handle.createMH,{:id => id}, FieldSet.opt(cols,id_handle[:model_name])).first
    end

    def is_assembly?()
      nil
    end
    def is_base_component?()
      nil
    end

    #may deprecate below
    def self.get_display_name(id_handle)
      get_object_scalar_column(id_handle,:display_name)
    end


    #TODO: deprecate or write in terms of get_objects_from_search_object
    #may do so by having constructor for search object that takes model_handle and filter
    #TODO: this fn is limited in how ir deals with vcols on column list;
    def self.get_objects(model_handle,where_clause={},opts={})
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
          right_ds = @db.get_objects_just_dataset(model_handle.createMH(join_info[:model_name]),nil,rs_opts)
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
      get_objects(id_handle.createMH(id_info[:relation_type]),{:id => id_info[:id]},opts).first
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

    def materialize_virtual_columns(*virtual_cols)
      virtual_cols.inject(self){|h,vc|h.merge(vc => self[vc])}
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

