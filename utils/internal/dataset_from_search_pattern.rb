module XYZ
  module SQL
    class DataSetSearchPattern < Dataset
      def initialize(db,model_handle,json_search)
        sequel_ds = ret_sequel_ds_from_json(db.dataset(),json_search)
        super(model_handle,sequel_ds)
      end

      def ret_sequel_ds_from_json(ds,json_search)
        ret_sequel_ds_from_hash!(ds,SON.parse(json_search))
      end

      def ret_sequel_ds_from_hash(ds,hash_dataset)
        ds_add = ret_sequel_ds_with_relation(ds,hash_dataset)
        return ds unless ds_add; ds = ds_add
        
        ds_add = ret_sequel_ds_with_columns(ds,hash_dataset)
        return ds unless ds_add; ds = ds_add

        ds_add = ret_sequel_ds_with_filter(ds,hash_dataset)
      end

     private
      def ret_sequel_ds_with_relation(ds,hash_dataset)
        relation_str = find(:relation,hash_dataset)
        return nil unless relation_str
        model_name = relation_str.to_sym
        sql_tbl_name = DB.self.sequel_table_name(model_name)
        unless sql_tbl_name
          Log.error("illegal relation given #{relation_str}") 
          return nil
        end
        ds.from(sql_tbl_name)
      end

      def ret_sequel_ds_with_columns(ds,hash_dataset)
        columns = find(:columns,hash_dataset)
        #form will be an array with each term either token or {:foo => :alias}; 
        #TODO: right now only treating col as string or term
        sequel_cols = columns.map do |col| 
          if col.kind_of?(Symbol) or col.kind_of?(String)
            convert_symbol(col)
          elsif col.kind_of?(Hash) and col.size = 1
            {convert_symbol(col.its_key) => convert_symbol(col.its_value)}
          else
            raise ErrorPatternNotImplemented.new(:column,col)
          end
        end
        ds.select(*sequel_cols)
      end

      def ret_sequel_ds_with_filter(ds,hash_dataset)
        filter = find(:filter,hash_dataset)
        return ds unless filter

        #TODO: just treating some subset of patterns
        sequel_where_clause =
          if filter.kind_of?(Array)
            op,args = get_op_and_args(filter)
            raise ErrorPatternNotImplemented.new(:filter_operation,op) unless op == :and
            #TODO: just treating eq
            and_list = filter.map do |el|
              el_op,el_args = get_op_and_args(el) 
              raise ErrorPatternNotImplemented.new(:equal_op,el) unless el_op == :eq and el_args.size == 2
              {convert_symbol(args[0]) => convert_symbol(args[1])}
            end
            SQL.and(*and_list)
          else
            raise ErrorPatternNotImplemented.new(:filter,filter)
          end
        ds.where(sequel_where_clause)
      end

      def find(type,hash_dataset)
        key_val = hash_dataset.find{|obj|obj.its_key() == type}
        key_val ? its_value(key_val) : nil
      end

      def its_key(key_value)
        return nil unless key_value.kind_of?(Hash)
        key_value.keys.first.to_sym
      end
      def its_value(key_value)
        return nil unless key_value.kind_of?(Hash)
        key_value.values.first
      end

      #return op in symbol form and args
      def get_op_and_args(expr)
        raise ErrorParsing.new(:expression,expr) unless expr.kind_of?(Array)
        [convert_symbol(expr.first),expr[1..expr.size-1]]
      end

      #converts if symbol still in string form; otehrwise keeps as string
      def convert_symbol(term_in_json)
        return term_in_json if term_in_json.kind_of?(Symbol)
        raise ErrorParsing.new(:symbol,term_in_json) unless term_in_json.kind_of?(String)
        return term_in_json 
        term_in_json =~ /^:/ ? term_in_json[1..term_in_json.size-1].to_sym : term_in_json 
      end

      class ErrorParsing < Error
        def initialize(type,obj)
          super("parsing item #{type} is not supported; it has form: #{object.inspect}")
        end
      end
      class ErrorPatternNotImplemented < ErrorNotImplemented
        def initialize(type,obj)
          super("parsing item #{type} is not supported; it has form: #{object.inspect}")
        end
      end
    end
  end
end
