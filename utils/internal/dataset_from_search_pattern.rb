#TODO: see if can collapse or better integrate with field_search_pattern.rb
module XYZ
  module SQL
    class DataSetSearchPattern < Dataset
      class << self
        def create_dataset_from_search_object(search_object)
          db = search_object.db
          search_pattern = search_object.search_pattern

          relation_in_search_pattern = search_pattern.find_key(:relation)
          mh_in_search_pattern = search_object.model_handle.createMH(:model_name => relation_in_search_pattern) 

          unless [String,Symbol].find{|t|relation_in_search_pattern.kind_of?(t)}
            raise ErrorNotImplemented.new("search pattern with relation #{relation_in_search_pattern.inspect}")
          end
          raise Error.new("illegal model name (#{relation_in_search_pattern}) in search pattern") unless DB_REL_DEF[relation_in_search_pattern]

          sequel_ds = ret_sequel_ds_from_hash(db.empty_dataset(),search_pattern,mh_in_search_pattern)

          sequel_ds ? self.new(mh_in_search_pattern,sequel_ds) : nil
        end

       private
        def ret_sequel_ds_from_hash(ds,search_pattern,model_handle)
          ds_add = ret_sequel_ds_with_relation(ds,search_pattern)
          return nil unless ds_add; ds = ds_add
        
          ds_add = ret_sequel_ds_with_columns(ds,search_pattern,model_handle)
          return nil unless ds_add; ds = ds_add

          ret_sequel_ds_with_filter(ds,search_pattern)
        end

        def ret_sequel_ds_with_relation(ds,search_pattern)
          relation = search_pattern.find_key(:relation)
          raise ErrorPatternNotImplemented.new(:relation,relation) unless relation.kind_of?(Symbol)
          sql_tbl_name = DB.sequel_table_name(relation)
          unless sql_tbl_name
            Log.error("illegal relation given #{relation}") 
            return nil
          end
          ds.from(sql_tbl_name)
        end
        
        def ret_sequel_ds_with_columns(ds,search_pattern,model_handle)
          model_name = model_handle[:model_name]
          columns = search_pattern.find_key(:columns)

          if columns.nil?
            return ds
           #TODO: refine return ds.select(*Model::FieldSet.default(model_name).cols)
          end

          #form will be an array with each term either token or {:foo => :alias}; 
          unpruned_field_set =  Model::FieldSet.new(columns)
          processed_field_set =  unpruned_field_set.only_including(Model::FieldSet.all_real_scalar(model_name))

          related_columns = unpruned_field_set.related_columns(model_name)
          if related_columns and not related_columns.empty?
            cols_to_add = related_columns.map do |r|
              qualified_col = r[:join_cond].values.first
              #strip off model_name__ prefix and discard non matching prefixes
              (qualified_col =~ Regexp.new("^(.+)__(.+)$")) ? ($1.to_sym == model_name ? $2 : nil) : qualified_col  
            end.compact
            processed_field_set.add_cols(*cols_to_add)
          end

          #alwas include id column
          processed_field_set.add_col?(:id)
          ds.select(*(processed_field_set.cols))
        end

        def ret_sequel_ds_with_filter(ds,search_pattern)
          filter = search_pattern.find_key(:filter)
          return ds unless filter

          #TODO: just treating some subset of patterns
          op,args = get_op_and_args(filter)
          raise ErrorPatternNotImplemented.new(:filter_operation,op) unless (op == :and)
          and_list = args.map do |el|
            el_op,el_args = get_op_and_args(el)
            case el_op
             when :eq
              {el_args[0] => el_args[1]}
             when :lt
              el_args[0].to_s.lit < el_args[1].to_s.lit
             when :lte
              el_args[0].to_s.lit <= el_args[1].to_s.lit
             when :gt
              el_args[0].to_s.lit > el_args[1].to_s.lit
             when :gte
              el_args[0].to_s.lit >= el_args[1].to_s.lit
             when "match-prefix".to_sym
              Sequel::SQL::StringExpression.like(el_args[0],"#{el_args[1]}%",{:case_insensitive=>true})
             when :regex
              Sequel::SQL::StringExpression.like(el_args[0],Regexp.new(el_args[1]),{:case_insensitive=>true})
             else
              raise ErrorPatternNotImplemented.new(:equal_op,el_op) 
            end
          end
          sequel_where_clause = SQL.and(*and_list)
          ds.where(sequel_where_clause)
        end

        #return op in symbol form and args
        def get_op_and_args(expr)
          raise ErrorParsing.new(:expression,expr) unless expr.kind_of?(Array)
          [expr.first,expr[1..expr.size-1]]
        end

        class ErrorPatternNotImplemented < ErrorNotImplemented
          def initialize(type,object)
            super("parsing item #{type} is not supported; it has form: #{object.inspect}")
          end
        end
      end
    end
  end
end
