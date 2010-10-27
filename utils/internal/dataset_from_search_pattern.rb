module XYZ
  module SQL
    class DataSetSearchPattern < Dataset
      class << self
        def create_dataset_from_search_object(search_object)
          db = search_object.db
          search_pattern = search_object.search_pattern

          sequel_ds = ret_sequel_ds_from_hash(db.empty_dataset(),search_pattern)

          relation_in_search_pattern = search_pattern.find_key(:relation)
          unless [String,Symbol].find{|t|relation_in_search_pattern.kind_of?(t)}
            raise ErrorNotImplemented.new("search pattern with relation #{relation_in_search_pattern.inspect}")
          end
          relation_in_search_pattern =  ret_symbol(relation_in_search_pattern)
          raise Error.new("illegal model name (#{relation_in_search_pattern}) in search pattern") unless DB_REL_DEF[relation_in_search_pattern]

          mh_in_search_pattern = search_object.model_handle.createMH(:model_name => relation_in_search_pattern) 
          sequel_ds ? self.new(mh_in_search_pattern,sequel_ds) : nil
        end

        def find(type,hash_search_pattern)
          pair = hash_search_pattern.find{|k,v|ret_symbol(k) == type}
          pair ? pair[1] : nil
        end

        
       private
        def ret_sequel_ds_from_hash(ds,hash_search_pattern)
          ds_add = ret_sequel_ds_with_relation(ds,hash_search_pattern)
          return nil unless ds_add; ds = ds_add
        
          ds_add = ret_sequel_ds_with_columns(ds,hash_search_pattern)
          return nil unless ds_add; ds = ds_add

          ret_sequel_ds_with_filter(ds,hash_search_pattern)
        end

        def ret_sequel_ds_with_relation(ds,hash_search_pattern)
          relation_str = find(:relation,hash_search_pattern)
          return nil unless relation_str
          model_name = ret_symbol(relation_str)
          sql_tbl_name = DB.sequel_table_name(model_name)
          unless sql_tbl_name
            Log.error("illegal relation given #{relation_str}") 
            return nil
          end
          ds.from(sql_tbl_name)
        end
        
        def ret_sequel_ds_with_columns(ds,hash_search_pattern)
          columns = find(:columns,hash_search_pattern)
          #form will be an array with each term either token or {:foo => :alias}; 
          #TODO: right now only treating col as string or term
          sequel_cols = columns.map do |col| 
            if col.kind_of?(Symbol) or col.kind_of?(String)
              ret_symbol(col)
            elsif col.kind_of?(Hash) and col.size = 1
              {ret_symbol(ret_symbol_key(col)) => ret_symbol(Aux::ret_value(col))}
            else
              raise ErrorPatternNotImplemented.new(:column,col)
            end
          end
          ds.select(*sequel_cols)
        end

        def ret_sequel_ds_with_filter(ds,hash_search_pattern)
          filter = find(:filter,hash_search_pattern)
          return ds unless filter

          #TODO: just treating some subset of patterns
          if filter.kind_of?(Array)
            op,args = get_op_and_args(filter)
            raise ErrorPatternNotImplemented.new(:filter_operation,op) unless (op == :and)
            sequel_where_clause = and_list = args.map do |el|
              el_op,el_args = get_op_and_args(el)
              #TODO: just treating eq
              raise ErrorPatternNotImplemented.new(:equal_op,el) unless (el_op == :eq and el_args.size == 2)
              {ret_scalar(el_args[0]) => ret_scalar(el_args[1])}
            end
            SQL.and(*and_list)
          else
            raise ErrorPatternNotImplemented.new(:filter,filter)
          end
          ds.where(sequel_where_clause)
        end

        #return op in symbol form and args
        def get_op_and_args(expr)
          raise ErrorParsing.new(:expression,expr) unless expr.kind_of?(Array)
          [ret_symbol(expr.first),expr[1..expr.size-1]]
        end

        #converts if symbol still in string form; otehrwise keeps as string
        def ret_symbol(term_in_json)
          raise ErrorParsing.new(:symbol,term_in_json) if [Array,Hash].detect{|t|term_in_json.kind_of?(t)}
          #complexity due to handle case where have form :":columns"
          term_in_json.to_s.gsub(/^[:]+/,'').to_sym 
        end
        def ret_scalar(term_in_json)
          raise ErrorParsing.new(:symbol,term_in_json) if [Array,Hash].detect{|t|term_in_json.kind_of?(t)}
          #complexity due to handle case where have form :":columns"
          return term_in_json.to_s.gsub(/^[:]+/,'').to_sym if term_in_json.kind_of?(Symbol)
          return $1.to_sym if (term_in_json.kind_of?(String) and term_in_json =~ /^[:]+(.+)/)
          term_in_json
        end

        def ret_symbol_key(obj)
          ret_symbol(Aux::ret_key(obj))
        end

        class ErrorParsing < Error
          def initialize(type,object)
            super("parsing item #{type} is not supported; it has form: #{object.inspect}")
          end
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
