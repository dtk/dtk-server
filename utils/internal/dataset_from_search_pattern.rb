#TODO: refactor to take into account that search_object has been parsed already
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
          columns = search_pattern.find_key(:columns)
          #form will be an array with each term either token or {:foo => :alias}; 
          unpruned_field_set =  Model::FieldSet.new(columns)
          pruned_field_set =  unpruned_field_set.only_including(Model::FieldSet.all_real_scalar(model_handle[:model_name]))
          ds.select(*(pruned_field_set.cols))
        end

        def ret_sequel_ds_with_filter(ds,search_pattern)
          filter = search_pattern.find_key(:filter)
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
