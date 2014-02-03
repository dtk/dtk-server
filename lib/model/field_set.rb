require File.expand_path('field_search_pattern', File.dirname(__FILE__))
module XYZ
  module FieldSetInstanceMixin
    class FieldSet
      include FieldSearchPatternInstanceMixin
      attr_reader :cols, :model_name
      #TODO: so fieldset can be more advanced than array of scalrs; can have netsed structure
      def initialize(model_name,cols=Array.new,field_search_pattern=nil)
        @model_name = model_name.to_sym
        @cols = cols 
        @field_search_pattern = field_search_pattern
      end

      def include_col?(col)
        @cols.include?(col)
      end

      #TODO: handle also case where col or self contains a hash
      def add_col!(col)
        @cols << col unless @cols.include?(col)
        self
      end

      def with_added_cols(*cols)
        return self if cols.empty?
        ret_cols = @cols
        cols.each{|col| ret_cols << col unless ret_cols.include?(col)}
        FieldSet.new(@model_name,ret_cols)
      end

      def with_removed_cols(*cols)
        return self if cols.empty?
        FieldSet.new(@model_name,@cols - cols)
      end

      #difference between only_including and & is not sysmetric and provides for items in self which are form {alias => col}
      def only_including(field_set)
        #TODO: right now not checking non scalar
        FieldSet.new(@model_name,@cols.reject{|col| col.kind_of?(Symbol) and not field_set.cols.include?(col)})
      end

      def &(field_set)
        FieldSet.new(@model_name,@cols & field_set.cols)
      end

      def extra_local_columns(vcol_sql_fns=nil)
        return nil unless vcolumns = (DB_REL_DEF[model_name]||{})[:virtual_columns] 
        extra_cols = Array.new
        cols = vcol_sql_fns ? (@cols + vcol_sql_fns.keys) : @cols
        cols.each do |f|
          field_extra_cols = parse_local_dependencies(vcolumns[f])
          next if field_extra_cols.empty?
          field_extra_cols.each{|col| extra_cols << col unless (extra_cols.include?(col) or @cols.include?(col))}
        end
        extra_cols.empty? ? nil : extra_cols
      end

      def with_replaced_local_columns?()
        return nil unless vcolumns = (DB_REL_DEF[model_name]||{})[:virtual_columns] 
        extra_cols = Array.new
        removed_cols = Array.new
        @cols.each do |f|
          field_extra_cols = parse_local_dependencies(vcolumns[f])
          next if field_extra_cols.empty?
          removed_cols << f
          field_extra_cols.each{|col| extra_cols << col unless (extra_cols.include?(col) or @cols.include?(col))}
        end
        return nil if extra_cols.empty?
        FieldSet.new(@model_name,(@cols + extra_cols) - removed_cols)
      end

      def with_related_local_columns()
        extra_local_cols = extra_local_columns()
        return self unless extra_local_cols 
        FieldSet.new(@model_name,@cols + extra_local_cols)
      end


      #TODO!!!: this does not work properly when two or more virtual attributes point to same column, but not tagged with same dependency def
      def related_remote_column_info(vcol_sql_fns=nil)
        return nil if @cols.empty?
        return nil unless vcolumns = DB_REL_DEF[model_name][:virtual_columns]
        ret = Array.new
        defs_seen = Array.new
        cols = vcol_sql_fns ? (@cols + vcol_sql_fns.keys) : @cols
        cols.each do |f|
          next unless vcol_info = vcolumns[f] 
          deps, def_name = parse_remote_dependencies(vcol_info)
          next unless deps
          if def_name 
            next if defs_seen.include?(def_name)
            defs_seen << def_name
          end
          ret = ret + deps
        end
        ret.empty? ? nil : ret
      end


      def ret_where_clause_for_search_string(name_value_pairs)
        @field_search_pattern ? @field_search_pattern.ret_where_clause_for_search_string(name_value_pairs) : {}
      end          

      #returns foreign key columns in fieldset
      def foreign_key_info() 
        db_rel_cols = ((DB_REL_DEF[model_name]||{})[:columns]||[])
        ret = Hash.new
        db_rel_cols.each do |col,col_info|
          ret[col] = col_info if (col_info[:foreign_key_rel_type] and cols.include?(col))
        end
        ret
      end

      #field set in option list
      def self.opt(x,model_name=nil)
        field_set = 
          if x.kind_of?(Symbol) and x == :all
            FieldSetAll.new()
          elsif x.kind_of?(Array) 
            raise Error.new("model_name is not given") unless model_name
            FieldSet.new(model_name,x) 
          else
            x
          end
        {:field_set => field_set}
      end

      def self.default(model_name)
        ret_fieldset(model_name,:default) do |db_rel|
          non_hidden_columns(db_rel[:columns]) + non_hidden_columns(COMMON_REL_COLUMNS) + virtual_columns_in_fieldset(db_rel[:virtual_columns]) + many_to_one_cols(db_rel)
        end
      end

      def self.common(model_name)
        ret_fieldset(model_name,:default) do |db_rel|
          non_hidden_columns(COMMON_REL_COLUMNS)
        end
      end
               
      def self.all_real(model_name)
        ret_fieldset(model_name,:all_real) do |db_rel|
          real_cols(db_rel) + many_to_one_cols(db_rel)
        end
      end

      def self.all_real_scalar(model_name)
        ret_fieldset(model_name,:all_real_scalar) do |db_rel|
          real_cols(db_rel) 
        end
      end

      def self.all_settable(model_name)
        ret_fieldset(model_name,:all_settable) do |db_rel|
          real_cols(db_rel) + many_to_one_cols(db_rel) + virtual_settable_cols(db_rel)
        end
      end

      def self.all_settable_scalar(model_name)
        ret_fieldset(model_name,:all_settable_scalar) do |db_rel|
          real_cols(db_rel) + virtual_settable_cols(db_rel)
        end
      end

      def self.scalar_cols_with_types(model_name)
        db_rel = DB_REL_DEF[model_name]
        return nil unless db_rel
        ret = db_rel[:columns].inject({}){|h,kv|h.merge(kv[0] => kv[1][:type])}
        ret = db_rel[:virtual_columns].inject(ret){|h,kv|h.merge(kv[1][:type] ? {kv[0] => kv[1][:type]} : {})}
        ret = COMMON_REL_COLUMNS.inject(ret){|h,kv|h.merge(kv[0] => kv[1][:type])}
        many_to_one_cols(db_rel).inject(ret){|h,k|h.merge(k => ID_TYPES[:id])}
      end

     private
      #returns form [deps,def_name] where later can be null if no defs
      def parse_remote_dependencies(virtual_col_info)
        #special case is :possible_parents
        return [convert_to_remote_dependencies(virtual_col_info[:possible_parents]),nil] if virtual_col_info[:possible_parents]
        deps = virtual_col_info[:remote_dependencies]
        return nil unless deps
        return [deps,nil] if deps.kind_of?(Array)
        return [deps.values.first,deps.keys.first]
      end

      def parse_local_dependencies(virtual_col_info)
        return [] unless virtual_col_info
        #special case is :possible_parents
        return convert_to_local_dependencies(virtual_col_info[:possible_parents]) if virtual_col_info[:possible_parents]
        virtual_col_info[:local_dependencies] || []
      end

      def convert_to_remote_dependencies(possible_parents)
        possible_parents.map do |parent|
          fk_col = DB.ret_parent_id_field_name(DB_REL_DEF[parent],DB_REL_DEF[model_name])
          {
            :model_name => parent,
            :join_type => :left_outer,
            :join_cond=>{:id=>"#{model_name}__#{fk_col}".to_sym},
            :cols=>[:id, :display_name, :ref, :ref_num]
          }
        end
      end

      def convert_to_local_dependencies(possible_parents)
        possible_parents.map{|parent|DB.ret_parent_id_field_name(DB_REL_DEF[parent],DB_REL_DEF[model_name])}
      end

      def self.ret_fieldset(model_name_x,col_type,&block)
        model_name = model_name_x.to_sym
        db_rel = DB_REL_DEF[model_name]
        Fieldsets[col_type] ||= Hash.new
        col_info = Fieldsets[col_type]
        return col_info[model_name] if col_info[model_name]
        col_info[model_name] = FieldSet.new(model_name,block.call(db_rel),FieldSearchPattern.new(model_name,self))
      end

      Fieldsets = Hash.new

      def self.non_hidden_columns(cols_def)
        cols_def.reject{|k,v| v and v[:hidden]}.keys
      end

      def self.virtual_columns_in_fieldset(cols_def)
        cols_def.reject{|k,v| v and v[:hidden]}.keys
      end

      def self.real_cols(db_rel)
        db_rel[:columns].keys + COMMON_REL_COLUMNS.keys
      end

      def self.many_to_one_cols(db_rel)
        (db_rel[:many_to_one]||[]).map{|p|DB.ret_parent_id_field_name(DB_REL_DEF[p],db_rel)}
      end

      def self.virtual_settable_cols(db_rel)
        (db_rel[:virtual_columns]||[]).map{|vc,vc_info|vc if vc_info[:path]}.compact 
      end
    end

    class FieldSetAll < FieldSet
      def initalize(model_name=nil)
        super(model_name,Array.new)
      end
      def include_col?(col)
        true
      end
      def with_added_cols(*cols)
        self
      end
      def with_removed_cols(*cols)
        self
      end
      def &(field_set)
        FieldSet.new(field_set.model_name,field_set.cols)
      end
    end
  end
end

  
