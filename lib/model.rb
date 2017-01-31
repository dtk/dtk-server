#
# Copyright (C) 2010-2016 dtk contributors
#
# This file is part of the dtk project.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# TODO: needs cleanup and partitioning
# TODO: model_name and relation_type redundant
# TODO: move these down under class Model
require_relative('model/input_into_model')
require_relative('model/field_set')
require_relative('model/clone')
require_relative('model/get_items')

require_relative('model/schema')
require_relative('model/data')
require_relative('model/rails_class')

module DTK
  class Model < HashObject::Model
    require_relative('model/sp_hash')
    extend SpHash::Mixin
    include SpHash::Mixin

    require_relative('model/subclass_processing')
    extend SubclassProcessingClassMixin
    include SubclassProcessingMixin

    require_relative('model/name_and_id_mixins')
    extend NameAndIdClassMixin

    require_relative('model/pp_object_type')
    extend PPObjectType::ClassMixin
    include PPObjectType::Mixin

    extend ImportObject
    extend ExportObject

    extend RailsClass

    @@debug_dev_flag = false

    class << self
      attr_reader :db
      expose_methods_from_internal_object :db, %w(update_from_select update_from_hash_assignments update_instance execute_function get_instance_or_factory get_instance_scalar_values get_objects_just_dataset get_object_ids_wrt_parent get_parent_object exists? create_from_select create_from_select_for_migrate ret_id_handles_from_create_returning_ids create_from_hash create_simple_instance? delete_instance delete_instances delete_instances_wrt_parent process_raw_db_row!), benchmark: :all #, :benchmark => %w{create_from_hash} # :all
    end

    def self.inherited(child_class)
      return unless self == Model
      model_name = child_class.model_name
      (@model_classes ||= {})[model_name] = child_class
    end

    #======hash index methods

    def [](x)
      return super(x) if key?(x)
      vc_info = ret_info_if_is_virtual_column(x)
      if vc_info
        # first check if it has an explicit path or possible parents defined; otherwise look for fn
        if vc_info[:path]
          nested_value(*vc_info[:path])
        elsif vc_info[:possible_parents] && x == :parent_name
          ret_parent_name(vc_info[:possible_parents])
        elsif respond_to?(x)
          send(x)
        end
      end
    end

    def ret_parent_name(possible_parents)
      # one complication is if parent is same type as self then looking for "p2", rather than p; this is due
      # to how we got around problem of having unique table names when joining table to itself
      # TODO: is it better to see if can change the joining to not have teh "2" suffix
      possible_parents.each do |p|
        parent_obj = self[relation_type == p ? "#{p}2".to_sym : p]
        return "#{p}/#{parent_obj[:display_name]}" if parent_obj && parent_obj[:display_name]
      end
      nil
    end

    def ret_info_if_is_virtual_column(col)
      virtual_columns[col]
    end

    def virtual_columns
      self.class.db_rel[:virtual_columns] || {}
    end
    private :ret_parent_name, :virtual_columns, :ret_info_if_is_virtual_column

    #======end: hash index methods

    # opts can haev keys:
    #   :sql_filter
    #   :filter_proc
    #   :augmented
    #   :remove_dups
    def get_objs_helper(virtual_attr, result_col = nil, opts = {})
      result_col ||= Aux.singular?(virtual_attr).to_sym
      sp_hash = {
        cols: [virtual_attr]
      }
      if opts[:sql_filter]
        sp_hash.merge!(filter: opts[:sql_filter])
      end
      rows = get_objs(cols: [virtual_attr])
      ret = 
        if filter_proc = opts[:filter_proc]
          rows.map do |r|
            el = r
            if filter_proc.call(el)
              opts[:augmented] ? augmented_form(r, result_col) : el
            end
          end.compact
        elsif opts[:augmented]
          augmented_form(rows, result_col)
        else
          rows.map { |r| r[result_col] }
        end
      
      opts[:remove_dups] ? get_objs_helper_ret_with_remove_dups(ret) : ret
    end
    
    def get_objs_helper_ret_with_remove_dups(ret)
      unless ret.empty?
        if ret.first.respond_to?(:id)
          ret = ret.inject({}) { |h, r| h.merge(r.id => r) }.values 
        else
          Log.error("Unexpected that opts[:remove_dups] givin but rows dont have an id method")
        end
      end
      ret
    end
    private :get_objs_helper_ret_with_remove_dups

    #
    # Debug SQL methods (START)
    #

    def self.enable_debug
      @@debug_dev_flag = true
    end

    def self.debug_flag?
      @@debug_dev_flag
    end

    def self.disable_debug
      @@debug_dev_flag = false
    end

    def self.pp_sql_debug(sql, title = nil)
      title ||= 'Debugging SQL, generated SQL: '
      puts "::::::: #{title} :: (START) => "
      puts sql.gsub('"', '').gsub('SELECT', "\nSELECT")
      puts '< = (END) :::::::'
    end

    #
    # Debug SQL methods (END)
    #

    def get_obj_helper(virtual_attr, result_col = nil, opts = {})
      result_col ||= virtual_attr
      rows = get_objs_helper(virtual_attr, result_col, opts)
      if rows.size > 1
        filter = (opts[:sql_filter] ? " #{opts[:sql_filter]} " : '')
        Log.error("call to get_obj for #{model_handle[:model_name]} (virtual_attr=#{virtual_attr}#{filter}) returned more than one row")
      end
      rows.first
    end

    def augmented_form(r, result_col)
      if r.is_a?(Hash)
        ret = r.delete(result_col)
        return nil unless ret.is_a?(Hash)
        result_col_keys = ret.keys
        r.each { |k, v| ret[k] = v unless result_col_keys.include?(k) }
        ret
      else # r.kind_of?(Array)
        r.map { |el| augmented_form(el, result_col) }.compact
      end
    end
    private :augmented_form

    def self.model_name
      @model_name ||= model_name_helper(self)
    end
    def model_name
      @relation_type || self.class.model_name()
    end

    def self.model_name_with_subclass
      model_name_helper(self, no_subclass: true)
    end

    def self.model_class(model_name)
      unless ret = @model_classes[model_name]
        if ret = models_to_add(model_name)
          @model_classes[model_name] = ret
        else
          fail Error.new("Need to put model name (#{model_name}) in IndirectlyInheritedModels")
        end
      end
      ret
    end

    def self.core_columns
      [:id, :display_name, :group_id]
    end

    # parent_id field name for child_model_name with parent this
    def parent_id_field_name(child_model_name)
      id_handle().create_childMH(child_model_name).parent_id_field_name()
    end

    def self.normalize_model(model_name)
      (model_name == :datacenter ? :target : model_name)
    end
    def self.matching_models?(mn1, mn2)
      normalize_model(mn1) == normalize_model(mn2)
    end

    def hash_subset(*cols)
      # set seed to model class w/o any keys
      Aux.hash_subset(self, cols, seed: self.class.create_stub(model_handle()))
    end

    def hash_form_subset(*cols)
      # set seed to model class w/o any keys
      Aux.hash_subset(self, cols, seed: {})
    end

    module Delim
      Char = '_'
      Common = "#{Char}#{Char}"
      NumericIndex = Char
      DisplayName = Common
      RegexpCommon = Regexp.new(Common)
      NumericIndexRegexp = Regexp.new("#{Common}#{NumericIndex}([0-9]+)")
    end

    include FieldSetInstanceMixin
    extend Clone::ClassMixins
    include Clone::Mixins
    extend InputIntoModelClassMixins
    include GetItemsInstanceMixins

    # TBD: refactoring: below is old to be refactored; above is refactored
    extend ModelSchemaClassMixins
    extend ModelDataClassMixins
    include ModelDataInstanceMixins

    # created before has id
    # use param name hash_values rather than hash_scalar_values because can have nested objects
    def self.create_stub(model_handle, hash_values = {})
      self.new(hash_values, model_handle[:c], model_name(), model_handle.create_stubIDH())
    end
    # this may be overwritten by the models
    def self.create(hash_scalar_values, c, relation_type_x = model_name(), id_handle = nil)
      self.new(hash_scalar_values, c, relation_type_x, id_handle)
    end

    # for, e.g., creating NodeGroup from Node object
    def self.create_as(superclass_obj)
      idh = superclass_obj.id_handle
      create(superclass_obj, idh[:c], model_name, idh)
    end

    # TODO: make initialize and use create
    def initialize(hash_scalar_values, c, relation_type_x = nil, id_handle = nil)
      return nil if hash_scalar_values.nil?
      super(hash_scalar_values)
      relation_type_x ||= model_name()
      relation_type = self.class.concrete_model_name(relation_type_x)
      @c = c
      @relation_type = relation_type
      @id_handle = id_handle ||
        if hash_scalar_values[:id]
          ret_id_handle_from_db_id(hash_scalar_values[:id], relation_type)
        elsif hash_scalar_values[:uri]
          IDHandle[c: c, uri: hash_scalar_values[:uri]]
        else
          nil
        end
      if @id_handle
        @id_handle[:group_id] ||= hash_scalar_values[:group_id] if hash_scalar_values[:group_id]
      end
    end

    def self.copy_as(model_obj)
      create_from_model_or_id_handle(model_obj, model_obj.model_handle, model_obj.id_handle)
    end

    def self.create_from_model_handle(hash_scalar_values, model_handle)
      create_from_model_or_id_handle(hash_scalar_values, model_handle)
    end

    def self.create_from_model_or_id_handle(hash_scalar_values, model_handle, id_handle = nil)
      self.new(hash_scalar_values, model_handle[:c], model_handle[:model_name], id_handle)
    end
    private_class_method :create_from_model_or_id_handle

    def i18n_language
      @id_handle ? @id_handle.i18n_language() : R8::Config[:default_language]
    end

    def subset(*keys)
      self.class.new(Aux.hash_subset(self, keys), @c, @relation_type, @id_handle)
    end
    # subset with virtual columns; tehy get substituted for real columns
    # TODO: this may be good place to materialze vcs
    def subset_with_vcs(*keys_x)
      new_field_set = Model::FieldSet.new(@relation_type, keys_x).with_replaced_local_columns?()
      keys = new_field_set ? new_field_set.cols : keys_x
      subset(*keys)
    end

    attr_reader :relation_type, :c

    # id and mode_handle related methods
    def id
      return self[:id] if self[:id] #short cicuit
      id_handle ? id_handle.get_id() : nil
    end

    def display_name
      self[:display_name] || (update_object!(:display_name))[:display_name]
    end

    def set_id_handle(hash_or_idh)
      @id_handle = (hash_or_idh.is_a?(IDHandle) ? hash_or_idh : IDHandle[hash_or_idh])
    end

    def id_handle(hash_info = nil)
      hash_info ? @id_handle.createIDH(hash_info) : @id_handle
    end

    def id_handle_with_auth_info
      # TODO: can be made more efficient by putting this info in @id_handle during initial create
      return id_handle() if id_handle()[:group_id]
      group_id = group_id() || (update_object!(:group_id))[:group_id]
      @id_handle.merge!(group_id: group_id) if group_id
      @id_handle
    end

    def get_parent_id_handle
      id_handle.get_parent_id_handle()
    end

    # will have id and av_hash values
    def prune_with_values(av_hash)
      # note: using Model#hash_subset does not work because id_handle not set right
      id_handle().create_object().merge(av_hash)
    end

    def shallow_dup(*cols)
      update_object!(*cols)
      ret = id_handle().create_object()
      ([:id] + cols).uniq.each do |col|
        ret[col] = self[col]
      end
      ret
    end

    def model_handle(mn = nil)
      group_id = group_id()
      user_info = (group_id ? { group_id: group_id } : nil)
      mh = ModelHandle.new(@c, @relation_type, nil, user_info)
      mn ? mh.createMH(mn) : mh
    end

    def model_handle_with_auth_info(mn = nil)
      group_id = group_id() || (update_object!(:group_id))[:group_id]
      user_info = { group_id: group_id }
      mh = ModelHandle.new(@c, @relation_type, nil, user_info)
      mn ? mh.createMH(mn) : mh
    end

    def child_model_handle(child_mn)
      model_handle().create_childMH(child_mn)
    end

    def group_id
      self[:group_id] || (@id_handle && @id_handle[:group_id])
    end
    private :group_id

    #######
    # can be overriten
    def self.list(model_handle)
      sp_hash = {
        cols: common_columns()
      }
      get_objs(model_handle.createMH(model_name()), sp_hash)
    end

    def self.update_from_rows(model_handle, rows, opts = {})
      return nil if rows.empty?
      array_ds = SQL::ArrayDataset.create(db, rows, model_handle, opts.merge(convert_for_update: true))
      field_set = Model::FieldSet.new(model_handle[:model_name], rows.first.keys - [:id])
      update_from_select(model_handle, field_set, array_ds)
    end

    def update_hash_key(field, hash_key, hash_key_val)
      self[field] ||= {}
      self[field].merge!(hash_key => hash_key_val)
      fail Error.new('Cannot execute update without the object having an id') unless id()
      self.class.update_from_rows(model_handle, [{ :id => id(), field => { hash_key => hash_key_val } }], partial_value: true)
    end
    # TODO: check calss to update with opts having :partial_value=>true to see whether shoudl use variant of update_hash_key instead
    # where there is a deep merge on the field's value
    def update(scalar_assignments, opts = {})
      scalar_assignments = {} if model_handle[:model_name] == :node && scalar_assignments.key?(:hidden) && scalar_assignments.key?(:value_asserted)
      scalar_assignments.each { |k, v| self[k] = v }
      fail Error.new('Cannot execute update without the object having an id') unless id()
      self.class.update_from_rows(model_handle, [scalar_assignments.merge(id: id())], opts)
    end

    def self.update_rows_meeting_filter(model_handle, scalar_assignments, filter_hash, opts = {})
      where_clause = SQL::DataSetSearchPattern.ret_sequel_filter(filter_hash, model_handle)
      @db.update_rows_meeting_filter(model_handle, scalar_assignments, where_clause, opts)
    end

    def update_from_hash_assignments(scalar_assignments, opts = {})
      self.class.update_from_hash_assignments(id_handle, scalar_assignments, opts)
    end

    def self.create_from_rows(model_handle, rows, opts = {})
      ret = []
      return ret if rows.empty?
      select_ds = SQL::ArrayDataset.create(db, rows, model_handle, opts[:convert] ? { convert_for_create: true } : {})
      override_attrs = {}
      create_opts = Aux.hash_subset(opts, [:returning_sql_cols, :duplicate_refs])
      ret_obj = opts[:ret_obj]
      if ret_obj
        create_opts[:returning_sql_cols] ||= ret_obj[:cols] || DefaultRetSqlCols
      end
      field_set = FieldSet.new(model_handle[:model_name], rows.first.keys)
      ret = create_from_select(model_handle, field_set, select_ds, override_attrs, create_opts)
      if ret_obj
        subclass_model_name = ret_obj[:model_name]
        ret.map do |hash_row|
          create_obj_optional_subclass(model_handle, hash_row, subclass_model_name)
        end
      else
        ret
      end
    end
    DefaultRetSqlCols = [:id, :group_id, :display_name]
    def self.add_default_cols?(cols = nil)
      default_cols = DefaultRetSqlCols
      if cols
        (cols + default_cols).uniq
      else
        default_cols
      end
    end
    def add_default_cols?(cols = nil)
      self.class.add_default_cols?(cols)
    end

    def self.create_from_rows_for_migrate(model_handle, rows)
      select_ds = SQL::ArrayDataset.create(db, rows, model_handle, convert_for_create: true)
      field_set = FieldSet.new(model_handle[:model_name], rows.first.keys)
      create_from_select_for_migrate(model_handle, field_set, select_ds)
    end

    def self.create_from_row(model_handle, row, opts = {})
      create_from_rows(model_handle, [row], opts).first
    end

    def Transaction(*args, &block)
      self.class.Transaction(*args, &block)
    end
    def self.Transaction(*args, &block)
      @db.transaction(*args, &block)
    end

    def self.RollbackTransaction
      raise ::Sequel::Rollback
    end

    # adds or deletes children based on match_cols
    # returns the list of idhs that have been created or modified
    # opts can include teh Booelan options
    #  :no_delete
    #  :update_matching
    #  :convert (used if have field with json structure)
    #
    def self.modify_children_from_rows(model_handle, parent_idh, rows, match_cols = [:ref], opts = {})
      parent_id_col = DB.parent_field(parent_idh[:model_name], model_handle[:model_name])
      parent_fields = { parent_id_col => parent_idh.get_id(), :group_id => parent_idh[:group_id] }
      basic_cols = (has_group_id_col?(model_handle) ? [:id, :group_id] : [:id])
      sp_hash = {
        cols: basic_cols + (match_cols - basic_cols),
        filter: [:eq, parent_id_col, parent_idh.get_id()]
      }
      existing = get_objs(model_handle, sp_hash, keep_ref_cols: true)
      if existing.empty? #shortcut
        create_rows = rows.map { |r| parent_fields.merge(r) }
        model_handle_with_par = model_handle
        unless model_handle_with_par[:parent_model_name]
          model_handle_with_par = model_handle_with_par.merge(parent_model_name: parent_idh[:model_name])
        end
        opts_create = Aux.hash_subset(opts, [:convert]).merge(duplicate_refs: :no_check)
        return create_from_rows(model_handle_with_par, create_rows, opts_create)
      end

      ret = []
      pruned_rows = []
      updated_rows = []
      rows.each do |r|
        if match = match_found(r, existing, match_cols)
          match_id = match[:id]
          ret << model_handle.createIDH(id: match_id)
          if opts[:update_matching]
            updated_rows << (r[:id] ? r : r.merge(id: match_id))
          end
        else
          pruned_rows << r
        end
      end

      unless updated_rows.empty?
        ret += update_from_rows(model_handle, updated_rows) || []
      end

      # add only ones not existing
      unless pruned_rows.empty?
        create_rows = pruned_rows.map { |r| parent_fields.merge(r) }
        ret += create_from_rows(model_handle, create_rows, duplicate_refs: :no_check)
      end

      # delete ones that not in rows
      unless opts[:no_delete]
        delete_idhs = existing.reject { |r| match_found(r, rows, match_cols) }.map { |r| model_handle.createIDH(id: r[:id]) }
        delete_instances(delete_idhs) unless delete_idhs.empty?
      end
      ret
    end

    # TODO: think may subsume below by above
    # creates if does not exist using match_assigns; in eitehr case returns id_handle
    # if block is given, called only if new row is created
    def self.create_from_row?(model_handle, ref, match_assigns, other_assigns = {}, opts = {}, &pre_create_row_block)
      sp_hash = {
        cols: (has_group_id_col?(model_handle) ? [:id, :group_id] : [:id])
      }
      filter_els = match_assigns.map { |k, v| [:eq, k, v] }
      if filter_els.size > 0
        sp_hash.merge!(filter: filter_els.size == 1 ? filter_els.first : [:and] + filter_els)
      end
      if matching_obj = get_obj(model_handle, sp_hash)
        matching_obj.id_handle()
      else
        if pre_create_row_block
          yield
        end
        create_from_row(model_handle, { ref: ref }.merge(match_assigns).merge(other_assigns), opts.merge(duplicate_refs: :no_check))
      end
    end

    def delete_instances(idh_list)
      self.class.delete_instances(idh_list)
    end

    def delete_instance(idh)
      self.class.delete_instance(idh)
    end

    def self.has_group_id_col?(model_handle)
      not [:user, :user_group, :user_group_relation].include?(model_handle[:model_name])
    end

    def self.match_found(el, el_list, cols)
      el_list.find do |el_in_list|
        not cols.find { |col| not (el[col] == el_in_list[col]) }
      end
    end
    private_class_method :match_found

    def self.select_process_and_update(model_handle, cols_x, id_list, _opts = {}, &block)
      cols = cols_x.include?(:id) ? cols_x : cols_x + [:id]
      fs = Model::FieldSet.opt(cols, model_handle[:model_name])
      wc = SQL.in(:id, id_list)
      existing_rows = get_objects_just_dataset(model_handle, wc, fs).for_update().all()
      modified_rows = block.call(existing_rows)
      # TODO: should check that every id in id_list appears in modified_rows
      update_from_rows(model_handle, modified_rows)
    end

    def self.get_objects_from_search_object(search_object, opts = {})
      PerformanceService.start('PERF_SQL', search_object.object_id)
      dataset = search_object.create_dataset()

      # [Haris] DEBUG SQL DEBUG HERE
      if debug_flag?
        pp_sql_debug(dataset.sequel_ds.sql, 'SELECT STATMENTS') if dataset
        ap 'OUTPUT: '
        ap dataset.all(opts) if dataset
      end

      ret_val = dataset ? dataset.all(opts) : nil

      PerformanceService.end('PERF_SQL', search_object.object_id)
      PerformanceService.log("TABLE=#{search_object[:search_pattern][:relation]}")
      PerformanceService.log('SQL=' + dataset.sequel_ds.sql.gsub(/"/, ''))

      ret_val
    end

    def self.get_objects_from_join_array(model_handle, base_sp_hash, join_array, opts = {})
      base_sp = SearchPatternSimple.new(base_sp_hash)
      dataset = SQL::DataSetSearchPattern.create_dataset_from_join_array(model_handle, base_sp, join_array)
      dataset ? dataset.all(opts) : nil
    end

    def get_children_objs(child_model_name, sp_hash_x, opts = {})
      parent_col_clause = [:eq, DB.parent_field(model_name, child_model_name), id()]
      sp_hash = HashSearchPattern.add_to_filter(sp_hash_x, parent_col_clause)
      child_model_handle = model_handle.createMH(child_model_name)
      self.class.get_objs(child_model_handle, sp_hash, opts)
    end
    # TODO: deprecate below
    def get_children_from_sp_hash(child_model_name, sp_hash_x, opts = {})
      parent_col_clause = [:eq, DB.parent_field(model_name, child_model_name), id()]
      sp_hash = HashSearchPattern.add_to_filter(sp_hash_x, parent_col_clause)
      child_model_handle = model_handle.createMH(child_model_name)
      self.class.get_objects_from_sp_hash(child_model_handle, sp_hash, opts)
    end

    def update_object!(*cols_x)
      cols = (cols_x.include?(:group_id) ? cols_x : cols_x + [:group_id]) #always good to get group_id
      cols = (cols.include?(:display_name) ? cols : cols + [:display_name]) #always good to get display_name
      cols_to_get =  cols.reject { |col| self.key?(col) }
      return self if cols_to_get.empty?
      debug_mode_possible_extra_db_calls(cols_to_get, :update_object)
      opts = (cols_to_get & [:ref, :ref_num]).empty? ? {} : { keep_ref_cols: true }
      if vals = get_objs({ cols: cols_to_get }, opts).first
        vals.each do |k, v|
          if cols.include?(k)
            self[k] = v
          end
        end
      end
      @id_handle[:group_id] ||= group_id()
      self
    end
    # TODO: deprecate above for below
    def update_obj!(*cols)
      cols_to_get =  cols.reject { |col| self.key?(col) }
      return self if cols_to_get.empty?
      opts = (cols_to_get & [:ref, :ref_num]).empty? ? {} : { keep_ref_cols: true }
      debug_mode_possible_extra_db_calls(cols_to_get, :update_obj)
      if vals = get_objs({ cols: cols_to_get }, opts).first
        vals.each do |k, v|
          if cols.include?(k)
            self[k] = v
          end
        end
      end
      if cols.include?(:group_id)
        @id_handle[:group_id] ||= group_id()
      end
      self
    end

    def debug_mode_possible_extra_db_calls(cols_to_get, tag)
      if R8::Config[:debug][:view_update_object]
        Log.info_pp([:debug_mode_possible_extra_db_calls, tag, self.class, self, cols_to_get, caller[0..7]])
      end
    end

    def get_field_from_db(field)
      update_obj!(field)[field]
    end

    # this returns field if exists, otherways gets it
    def get_field?(field)
      self[field] || update_obj!(field)[field]
    end

    def self.add_fields!(objects, cols)
      return objects if objects.empty?
      #short cicuit if all objects have all cols
      unless objects.find { |obj| not (cols - obj.keys).empty? }
        return objects
      end
      sp_hash = {
        cols: cols.include?(:id) ? cols : cols + [:id],
        filter: [:oneof, :id, objects.map(&:id)]
      }
      mh = objects.first.model_handle
      ndx_rows = get_objs(mh, sp_hash).inject({}) do |h, r|
        h.merge(r[:id] => r)
      end
      objects.each do |obj|
        obj.merge!(ndx_rows[obj.id()])
      end
      objects
    end

    def update_and_materialize_object!(*cols)
      update_object!(*cols).materialize!(cols)
    end

    def get_obj(sp_hash, opts = {})
      rows = get_objs(sp_hash, opts)
      if rows.size > 1
        Log.error_pp(["call to get_obj for #{model_handle[:model_name]} (sp_hash=#{sp_hash.inspect} returned more than one row:", rows, caller[0..5]])
      end
      rows.first
    end

    def get_objs(sp_hash_x, opts = {})
      sp_hash = HashSearchPattern.add_to_filter(sp_hash_x, [:eq, :id, id()])
      mh = opts[:model_handle] || model_handle()
      self.class.get_objs(mh, sp_hash, opts)
    end

    # TODO: remove get_objects_from_sp_hash
    def get_objects_from_sp_hash(sp_hash_x, opts = {})
      sp_hash = HashSearchPattern.add_to_filter(sp_hash_x, [:eq, :id, id()])
      self.class.get_objects_from_sp_hash(model_handle(), sp_hash, opts)
    end

    def get_objs_uniq(obj_col, col_in_result = nil)
      col_in_result ||= obj_col.to_s.gsub(/s$/, '').to_sym
      get_objs(cols: [obj_col]).inject({}) do |h, r|
        obj = r[col_in_result]
        id = obj[:id]
        h[obj[:id]] ||= obj
        h
      end.values
    end

    def get_objs_col(sp_hash_x, col = nil, opts = {})
      # if col not given assumption that sp_hash_x is of form {:cols => [col]} or symbol
      if sp_hash_x.is_a?(Symbol)
        sp_hash_x = { cols: [sp_hash_x] }
      end
      col ||= sp_hash_x[:cols].first
      get_objs(sp_hash_x, opts).map { |r| r[col] }.compact
    end
    # TODO: removeg et_objects_col_from_sp_hash
    def get_objects_col_from_sp_hash(sp_hash_x, col = nil, opts = {})
      # if col not given assumption that sp_hash_x is of form {:cols => [col]} or symbol
      if sp_hash_x.is_a?(Symbol)
        sp_hash_x = { cols: [sp_hash_x] }
      end
      col ||= sp_hash_x[:cols].first
      get_objects_from_sp_hash(sp_hash_x, opts).map { |r| r[col] }.compact
    end

    def self.get_objs_in_set(id_handles, sp_hash_x, opts = {})
      return [] if id_handles.empty?
      sample_idh = id_handles.first
      model_handle = sample_idh.createMH()
      sp_hash = HashSearchPattern.add_to_filter(sp_hash_x, [:oneof, :id, id_handles.map(&:get_id)])
      get_objs(model_handle, sp_hash, opts)
    end

    # TODO: deprecate get_objects_in_set_from_sp_hash
    def self.get_objects_in_set_from_sp_hash(id_handles, sp_hash_x, opts = {})
      return [] if id_handles.empty?
      sample_idh = id_handles.first
      model_handle = sample_idh.createMH()
      sp_hash = HashSearchPattern.add_to_filter(sp_hash_x, [:oneof, :id, id_handles.map(&:get_id)])
      get_objects_from_sp_hash(model_handle, sp_hash, opts)
    end

    def self.get_obj(model_handle, sp_hash, opts = {})
      rows = get_objs(model_handle, sp_hash, opts)
      if rows.size > 1
        Log.error_pp(["call to get_obj for #{model_handle[:model_name]} (sp_hash=#{sp_hash.inspect} returned more than one row:", rows, caller[0..5]])
      end
      rows.first
    end

    def self.get_objs(model_handle, sp_hash, opts = {})
      model_name = model_handle[:model_name]
      hash = sp_hash.merge(relation: model_name)
      search_object = SearchObject.create_from_input_hash({ 'search_pattern' => hash }, model_name, model_handle[:c])

      # TODO: putting this in here so we can remove :keep_ref_cols at top level
      opts_get_search_object = opts
      if !opts.key?(:keep_ref_cols) && (sp_hash[:cols] || []).include?(:ref)
        opts_get_search_object = opts.merge(keep_ref_cols: true)
      end

      ret = get_objects_from_search_object(search_object, opts_get_search_object)
      if subclass_model_name = opts[:subclass_model_name]
        ret.map { |r| r.create_subclass_obj(subclass_model_name) }
      else
        ret
      end
    end

    def self.get_by_id(id, mh, sp_hash)
      sp_hash.merge!(filter: [:eq, :id, id])
      get_objs(mh, sp_hash).first
    end

    # TODO: remove below
    def self.get_objects_from_sp_hash(model_handle, sp_hash, opts = {})
      model_name = model_handle[:model_name]
      hash = sp_hash.merge(relation: model_name)
      search_object = SearchObject.create_from_input_hash({ 'search_pattern' => hash }, model_name, model_handle[:c])
      get_objects_from_search_object(search_object, opts)
    end

    def get_object_columns(_id_handle, columns)
      self.class.get_object_columns(id_handle(), columns)
    end

    def self.get_object_columns(id_handle, columns)
      sp_hash = {
        relation: id_handle[:model_name],
        filter: [:and, [:eq, :id, id_handle.get_id()]],
        columns: columns
      }
      get_objects_from_sp_hash(id_handle.createMH(), sp_hash).first
    end

    def self.get_object_scalar_column(id_handle, col)
      (get_object_scalar_columns(id_handle, [col]) || {})[col]
    end

    def self.get_object_scalar_columns(id_handle, cols)
      id = id_handle && id_handle.get_id()
      return nil unless id
      @db.get_objects_scalar_columns(id_handle.createMH, { id: id }, FieldSet.opt(cols, id_handle[:model_name])).first
    end

    def is_assembly?
      nil
    end

    def assembly?(_opts = {})
     nil
    end

    # may deprecate below
    def self.get_display_name(id_handle)
      get_object_scalar_column(id_handle, :display_name)
    end

    # TODO: deprecate or write in terms of get_objects_from_search_object
    # may do so by having constructor for search object that takes model_handle and filter
    # TODO: this fn is limited in how ir deals with vcols on column list;
    def self.get_objects(model_handle, where_clause = {}, opts = {})
      model_name = model_handle[:model_name]

      base_field_set =  opts[:field_set] || FieldSet.default(model_name)
      field_set = opts[:field_set] ? base_field_set.with_related_local_columns() : base_field_set
      related_col_info = base_field_set.related_remote_column_info()

      ret = nil
      augmented_opts = opts.merge(FieldSet.opt(field_set))
      unless related_col_info
        ret = @db.get_objects_scalar_columns(model_handle, where_clause, augmented_opts)
      else
        graph_ds = get_objects_just_dataset(model_handle, where_clause, augmented_opts)
        related_col_info.each do |join_info|
          rs_opts = (join_info[:cols] ? FieldSet.opt(join_info[:cols], join_info[:model_name]) : {}).merge return_as_hash: true
          right_ds = @db.get_objects_just_dataset(model_handle.createMH(join_info[:model_name]), nil, rs_opts)
          graph_ds = graph_ds.graph(:left_outer, right_ds, join_info[:join_cond])
        end
        graph_ds = graph_ds.paging_and_order(opts)
        ret = graph_ds.all
      end
      ret
    end

    def self.get_object(id_handle, opts = {})
      c = id_handle[:c]
      id_info = IDInfoTable.get_row_from_id_handle id_handle, raise_error: opts[:raise_error], short_circuit_for_minimal_row: true
      return unless id_info && id_info[:id]
      get_objects(id_handle.createMH(id_info[:relation_type]), { id: id_info[:id] }, opts).first
    end

    def self.get_object_deep(id_handle, opts = {})
      @db.get_instance_or_factory(id_handle, nil, opts.merge(depth: :deep, no_hrefs: true))
    end

    def materialize!(cols)
      cols.each { |col| self[col] = self[col] unless self.key?(col) }
      self
    end

    protected

    # inherited virtual coulmn defs
    def parent_id
      return id_handle()[:guid] if id_handle() && id_handle()[:guid] #short circuit
      id_handle().get_parent_id_info()[:id]
    end

    def parent_path
      return id_handle()[:uri] if id_handle() && id_handle()[:uri] #short circuit
      id_handle().get_parent_id_info()[:uri]
    end
  end

  class RefObjectPairs < HashObject
  end
end
