require File.expand_path('field_search_pattern', File.dirname(__FILE__))
module XYZ
  module FieldSetInstanceMixin
    class FieldSet
      extend FieldSearchPatternInstanceMixin
      attr_reader :cols
      #TODO: so fieldset can be more advanced than array of scalrs; can have netsed structure
      def initialize(cols=Array.new,field_search_pattern=nil)
        @cols = cols 
        @field_search_pattern = field_search_pattern
      end

      def include_col?(col)
        @cols.include?(col)
      end

      def add_cols(*cols)
        cols.each{|col| @cols << col unless @cols.include?(col)}
      end

      def remove_cols(*cols)
        FieldSet.new(@cols - cols)
      end

      def &(field_set)
        FieldSet.new(@cols & field_set.cols)
      end

      def related_columns(model_name_x)
        model_name = model_name_x.to_sym
        return nil if @cols.empty?
        return nil unless vcolumns = DB_REL_DEF[model_name][:virtual_columns]
        ret = Array.new
        @cols.each do |f|
          next unless vcol_info = vcolumns[f] 
          #special case is :possible_parents
          next unless deps = convert_to_dependencies(model_name,vcol_info[:possible_parents]) || vcol_info[:dependencies]
          #TODO: optimize when two virtual columns join in same info with same conditions
          ret = ret + deps
        end
        ret.empty? ? nil : ret
      end

      def ret_where_clause_for_search_string(name_value_pairs)
        @field_search_pattern ? @field_search_pattern.ret_where_clause_for_search_string(name_value_pairs) : {}
      end          

      #field set in option list
      def self.opt(x)
        field_set = 
          if x.kind_of?(Symbol) and x == :all
            FieldSetAll.new()
          elsif x.kind_of?(Array) 
            FieldSet.new(x) 
          else
            x
          end
        {:field_set => field_set}
      end

     private
      def convert_to_dependencies(model_name,possible_parents)
        return nil if possible_parents.nil?
        #TODO: migh make geenral utility fn with inject Aux.hash_map
        possible_parents.map do |parent|
          fk_col = DB.ret_parent_id_field_name(DB_REL_DEF[parent],DB_REL_DEF[model_name])
          {
            :model_name => parent,
            :join_cond=>{:id=>"#{model_name}__#{fk_col}".to_sym},
            :cols=>[:id, :display_name, :ref, :ref_num]
          }
        end
      end
     public
      class << self
        def default(model_name_x)
          ret_fieldset(model_name_x,:default) do |db_rel|
            non_hidden_columns(db_rel[:columns]) + non_hidden_columns(COMMON_REL_COLUMNS) + virtual_columns_in_fieldset(db_rel[:virtual_columns]) + many_to_one_cols(db_rel)
          end
        end

        def all_real(model_name_x)
          ret_fieldset(model_name_x,:all_real) do |db_rel|
            real_cols(db_rel) + many_to_one_cols(db_rel)
          end
        end

        def all_real_scalar(model_name_x)
          ret_fieldset(model_name_x,:all_real_scalar) do |db_rel|
            real_cols(db_rel) 
          end
        end

        def all_settable(model_name_x)
          ret_fieldset(model_name_x,:all_settabler) do |db_rel|
            real_cols(db_rel) + many_to_one_cols(db_rel) + virtual_settable_cols(db_rel)
          end
        end

        def all_settable_scalar(model_name_x)
          ret_fieldset(model_name_x,:all_settable_scalar) do |db_rel|
            real_cols(db_rel) + virtual_settable_cols(db_rel)
          end
        end

        def real_cols_with_types(model_name)
          db_rel = DB_REL_DEF[model_name]
          db_rel_cols = db_rel[:columns].inject({}){|h,kv|h.merge(kv[0] => kv[1][:type])}
          COMMON_REL_COLUMNS.inject(db_rel_cols){|h,kv|h.merge(kv[0] => kv[1][:type])}
        end

       private

        def ret_fieldset(model_name_x,col_type,&block)
          model_name = model_name_x.to_sym
          db_rel = DB_REL_DEF[model_name]
          Fieldsets[col_type] ||= Hash.new
          col_info = Fieldsets[col_type]
          return col_info[model_name] if col_info[model_name]
          col_info[model_name] = FieldSet.new(block.call(db_rel),FieldSearchPattern.new(model_name,self))
        end

        #TBD: may instead put in DB_REL_DEF
        Fieldsets = Hash.new

        def non_hidden_columns(cols_def)
          cols_def.reject{|k,v| v and v[:hidden]}.keys
        end

        def virtual_columns_in_fieldset(cols_def)
          cols_def.reject{|k,v| v and v[:hidden]}.keys
        end

        def real_cols(db_rel)
          db_rel[:columns].keys + COMMON_REL_COLUMNS.keys
        end
        def many_to_one_cols(db_rel)
          (db_rel[:many_to_one]||[]).map{|p|DB.ret_parent_id_field_name(DB_REL_DEF[p],db_rel)}
        end
        def virtual_settable_cols(db_rel)
          (db_rel[:virtual_columns]||[]).map{|vc,vc_info|vc if vc_info[:path]}.compact 
        end
      end
    end
    class FieldSetAll < FieldSet
      def initalize()
        super(Array.new)
      end
      def include_col?(col)
        true
      end
      def add_cols(*cols)
      end
      def remove_cols(*cols)
      end
      def &(field_set)
        FieldSet.new(field_set.cols)
      end
    end
  end
end

  
