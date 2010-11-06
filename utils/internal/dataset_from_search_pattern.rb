#TODO: see if can collapse or better integrate with field_search_pattern.rb
module XYZ
  module SQL
    class DataSetSearchPattern < Dataset
      class << self
        def create_dataset_from_search_object(search_object)
          search_pattern = search_object.search_pattern
          raise Error.new("search pattern is nil") unless search_pattern
          raise ErrorNotImplemented.new("processing of search pattern of type #{search_pattern.class.to_s}") unless search_pattern.kind_of?(SearchPatternSimple)
          relation_in_search_pattern = search_pattern.find_key(:relation)
          mh_in_search_pattern = search_object.model_handle.createMH(:model_name => relation_in_search_pattern) 

          raise Error.new("illegal model name (#{relation_in_search_pattern}) in search pattern") unless DB_REL_DEF[relation_in_search_pattern]

          sequel_ds = ret_sequel_ds_from_hash(search_object.db.empty_dataset(),search_pattern,mh_in_search_pattern)
          return nil unless sequel_ds
          process_local_and_remote_dependencies(search_object,self.new(mh_in_search_pattern,sequel_ds))
        end

       private
        def process_local_and_remote_dependencies(search_object,simple_dataset)
          model_handle = simple_dataset.model_handle()
          pp [:wo_related_col,simple_dataset.ppsql]
          related_col_info = search_object.field_set().related_remote_column_info()

          return simple_dataset unless related_col_info

          
          graph_ds = simple_dataset.from_self(:alias => model_handle[:model_name])
          related_col_info.each do |join_info|
            rs_opts = (join_info[:cols] ? Model::FieldSet.opt(join_info[:cols],join_info[:model_name]) : {}).merge :return_as_hash => true
            right_ds = search_object.db.get_objects_just_dataset(model_handle.createMH(:model_name => join_info[:model_name]),nil,rs_opts)
            graph_ds = graph_ds.graph(:left_outer,right_ds,join_info[:join_cond])
          end
          opts = {} #TODO: stub
          graph_ds.paging_and_order(opts)
        end

        def ret_sequel_ds_from_hash(ds,search_pattern,model_handle)
          ds_add = ret_sequel_ds_with_relation(ds,search_pattern)
          return nil unless ds_add; ds = ds_add
        
          ds_add = ret_sequel_ds_with_columns(ds,search_pattern,model_handle)
          return nil unless ds_add; ds = ds_add
          
          ds = ret_sequel_ds_with_filter(ds,search_pattern)
          ret_sequel_ds_with_order_by_and_paging(ds,search_pattern)
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
          base_field_set = search_pattern.field_set()
          model_name = model_handle[:model_name]
          columns = base_field_set.cols
          return ds if columns.empty? 

          #first prune out all non scalar real columns
          processed_field_set =  base_field_set.only_including(Model::FieldSet.all_real_scalar(model_name))

          #compute cols_to_add by looking at both local columns and ones that are in join conditions to enable remote columns to be joined in
          #do not have to worry about duplicayes because with_added_cols will do that
          cols_to_add = Array.new

          related_col_info = base_field_set.related_remote_column_info()
          if related_col_info and not related_col_info.empty?
            cols_to_add_remote = related_col_info.map do |r|
              qualified_col = r[:join_cond].values.first
              #strip off model_name__ prefix and discard non matching prefixes
              (qualified_col.to_s =~ Regexp.new("^(.+)__(.+)$")) ? ($1.to_sym == model_name ? $2.to_sym : nil) : qualified_col  
            end.compact
            cols_to_add = cols_to_add + cols_to_add_remote
          end

          cols_to_add_local = base_field_set.extra_local_columns()
          cols_to_add = cols_to_add + cols_to_add_local if cols_to_add_local

          processed_field_set = processed_field_set.with_added_cols(*cols_to_add) 
          #always include id column
          processed_field_set.add_col!(:id)
          ds.select(*(processed_field_set.cols))
        end

        def ret_sequel_ds_with_filter(ds,search_pattern)
          filter = search_pattern.find_key(:filter)
          return ds if filter.empty?

          #TODO: just treating "and" now
          #TODO: some below use Sequel others are wrapper SQL in sql.rb; clean up
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
             when :oneof
              SQL.or(*el_args[1].map{|x|{el_args[0] => x}})
             else
              raise ErrorPatternNotImplemented.new(:equal_op,el_op) 
            end
          end
          sequel_where_clause = SQL.and(*and_list)
          ds.where(sequel_where_clause)
        end

        def ret_sequel_ds_with_order_by_and_paging(ds,search_pattern)
          order_by = search_pattern.find_key(:order_by)
          paging = search_pattern.find_key(:paging)
          DB.ret_paging_and_order_added_to_dataset(ds,{:order_by => order_by, :paging => paging})
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
