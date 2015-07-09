# TODO: see if can collapse or better integrate with field_search_pattern.rb
module XYZ
  module SQL
    class DataSetSearchPattern < Dataset
      class << self
        def create_dataset_from_search_object(search_object)
          search_pattern = search_object.search_pattern
          raise Error.new('search pattern is nil') unless search_pattern
          raise Error::NotImplemented.new("processing of search pattern of type #{search_pattern.class}") unless search_pattern.is_a?(SearchPatternSimple)
          relation_in_search_pattern = search_pattern.find_key(:relation)
          mh_in_search_pattern = search_object.model_handle.createMH(model_name: relation_in_search_pattern)

          raise Error.new("illegal model name (#{relation_in_search_pattern}) in search pattern") unless DB_REL_DEF[relation_in_search_pattern]

          sequel_filter_wo_auth,vcol_sql_fns = SimpleSearchPattern::ret_sequel_filter_and_vcol_sql_fns(search_pattern,mh_in_search_pattern)
          sequel_filter = DB.augment_for_authorization(sequel_filter_wo_auth,mh_in_search_pattern)
          remote_col_info = search_object.related_remote_column_info(vcol_sql_fns)
          sequel_ds = SimpleSearchPattern::ret_sequel_ds_with_sequel_filter(mh_in_search_pattern,search_pattern,sequel_filter,remote_col_info,vcol_sql_fns)
          return nil unless sequel_ds
          process_local_and_remote_dependencies(search_object,self.new(mh_in_search_pattern,sequel_ds),remote_col_info,vcol_sql_fns)
        end

        def create_dataset_from_join_array(model_handle,base_search_pattern,join_array)
          db = model_handle.db
          graph_ds = Dataset.new(model_handle,SimpleSearchPattern::ret_sequel_ds(model_handle,base_search_pattern)).from_self(alias: model_handle[:model_name])
          join_array.each do |join_info|
            right_ds = nil
            right_ds_mh = model_handle.createMH(model_name: join_info[:model_name])
            if join_info[:sequel_def] #override with sequel def
              sequel_ds = join_info[:sequel_def].call(db.dataset(DB_REL_DEF[join_info[:model_name]]))
              right_ds = Dataset.new(right_ds_mh,sequel_ds)
            else
              rs_opts = (join_info[:cols] ? Model::FieldSet.opt(join_info[:cols],join_info[:model_name]) : {}).merge return_as_hash: true
              filter = join_info[:filter] ? SimpleSearchPattern::ret_sequel_filter(join_info[:filter],join_info[:model_name]) : nil
              right_ds = db.get_objects_just_dataset(right_ds_mh,filter,rs_opts)
            end
            opts = join_info[:alias] ? {table_alias: join_info[:alias]} : {}
            opts.merge!(convert: true) if join_info[:convert]
            graph_ds = graph_ds.graph(join_info[:join_type]||:left_outer,right_ds,join_info[:join_cond],opts)
          end
          graph_ds
        end

        def ret_sequel_filter(filter_hash,model_handle)
          SimpleSearchPattern::ret_sequel_filter(filter_hash,model_handle[:model_name])
        end

        private

        def process_local_and_remote_dependencies(search_object,simple_dataset,remote_col_info=nil,vcol_sql_fns=nil)
          model_handle = simple_dataset.model_handle()
          base_field_set = search_object.field_set()
          unless remote_col_info || vcol_sql_fns
            opts = {} #TODO: stub
            return simple_dataset.paging_and_order(opts)
          end

          # join in any needed tables
          graph_ds = simple_dataset.from_self(alias: model_handle[:model_name])
          (remote_col_info||[]).each do |join_info|
            right_ds = nil
            right_ds_mh = model_handle.createMH(model_name: join_info[:model_name])
            if join_info[:sequel_def] #override with sequel def
              sequel_ds = join_info[:sequel_def].call(search_object.db.dataset(DB_REL_DEF[join_info[:model_name]]))
              right_ds = Dataset.new(right_ds_mh,sequel_ds)
            else
              rs_opts = (join_info[:cols] ? Model::FieldSet.opt(join_info[:cols],join_info[:model_name]) : {}).merge return_as_hash: true
              filter = join_info[:filter] ? SimpleSearchPattern::ret_sequel_filter(join_info[:filter],join_info[:model_name]) : nil
              right_ds = search_object.db.get_objects_just_dataset(right_ds_mh,filter,rs_opts)
            end
            opts = join_info[:alias] ? {table_alias: join_info[:alias]} : {}
            opts.merge!(convert: true) if join_info[:convert]
            graph_ds = graph_ds.graph(join_info[:join_type]||:left_outer,right_ds,join_info[:join_cond],opts)
          end

          # add any global columns or global where clauses
          if vcol_sql_fns
            wc_exprs = (vcol_sql_fns||[]).map{|_vcol,vcol_info| vcol_info[:sql_fn] ? vcol_info[:expr] : nil}.compact
            wc = (wc_exprs.empty? ? nil : SimpleSearchPattern::ret_sequel_filter([:and] + wc_exprs, model_handle))

            post_proc_exprs = (vcol_sql_fns||[]).map{|_vcol,vcol_info| vcol_info[:sql_fn] ? nil : vcol_info[:expr]}.compact
            post_proc_filter = (post_proc_exprs.empty? ? nil : [:and] + post_proc_exprs)

            vcol_values = (vcol_sql_fns||{}).map{|vcol,vcol_info|vcol_info[:sql_fn] ? {column: vcol, value: vcol_info[:sql_fn]} : nil}.compact

            graph_ds = graph_ds.add_virtual_column_aliases(vcol_values)
            graph_ds = graph_ds.from_self.where(wc) if wc
            graph_ds.add_filter_post_processing(post_proc_filter) if post_proc_filter
          end
          opts = {} #TODO: stub
          graph_ds.paging_and_order(opts)
        end

        module SimpleSearchPattern
          def self.ret_sequel_ds_with_sequel_filter(model_handle,search_pattern,sequel_filter,remote_col_info=nil,vcol_sql_fns=nil)
            ds = model_handle.db.empty_dataset()
            ds_add = ret_sequel_ds_with_relation(ds,search_pattern)
            return nil unless ds_add; ds = ds_add

            ds_add = ret_sequel_ds_with_columns(ds,search_pattern,model_handle,remote_col_info,vcol_sql_fns)
            return nil unless ds_add; ds = ds_add

            ds = ret_sequel_ds_with_filter(ds,sequel_filter)
            ret_sequel_ds_with_order_by_and_paging(ds,search_pattern)
          end
          # TODO: better relate these two methods
          def self.ret_sequel_ds(model_handle,search_pattern)
            ds = model_handle.db.empty_dataset()
            ds_add = ret_sequel_ds_with_relation(ds,search_pattern)
            return nil unless ds_add; ds = ds_add

            ds_add = ret_sequel_ds_with_columns(ds,search_pattern,model_handle)
            return nil unless ds_add; ds = ds_add

            sequel_filter = ret_filter_hash(search_pattern) && ret_sequel_filter(ret_filter_hash(search_pattern),model_handle)
            ds = ret_sequel_ds_with_filter(ds,sequel_filter)
            ret_sequel_ds_with_order_by_and_paging(ds,search_pattern)
          end

          def self.ret_sequel_filter_and_vcol_sql_fns(search_pattern,model_handle)
            filter_hash = search_pattern.find_key(:filter)
            return nil if filter_hash.empty?
            vcol_sql_fns = {}
            sequel_filter = ret_sequel_filter(filter_hash,model_handle,vcol_sql_fns)
            return [sequel_filter,vcol_sql_fns.empty? ? nil : vcol_sql_fns]
          end

          def self.ret_filter_hash(search_pattern)
            filter_hash = search_pattern.find_key(:filter)
            filter_hash.empty? ?nil : filter_hash
          end

          # if vcol_sql_fns is passed is nil then this wil not do any special processing on virtual columns; otehrwise it wil take out virtual columns and append unto this filter_hash
          def self.ret_sequel_filter(filter_hash,model_handle,vcol_sql_fns=nil)
            # TODO: just treating "and", "or", and "implicit "and"
            # TODO: some below use Sequel others are wrapper SQL in sql.rb; clean up
            op,args = get_op_and_args(filter_hash)
            unless [:and,:or].include?(op)
              # impilicit and
              args = [[op] + args]
              op = :and
            end
            and_list = []
            args.each do |el|
              el_op,el_args = get_filter_condition_op_and_args!(vcol_sql_fns,el,model_handle)
              # processes nested ands and ors
              if [:or,:and].include?(el_op)
                and_list << ret_sequel_filter(el,model_handle,vcol_sql_fns)
              else
                next if el_op.nil? #this can happen if el has a vcol in it
                and_list << case el_op
                 when :eq
                  ret_eq_comparison(el_args[0],el_args[1])
                 when :neq
                  SQL.not(ret_eq_comparison(el_args[0],el_args[1]))
                 when :lt
                  el_args[0].to_s.lit < el_args[1].to_s.lit
                 when :lte
                  el_args[0].to_s.lit <= el_args[1].to_s.lit
                 when :gt
                  el_args[0].to_s.lit > el_args[1].to_s.lit
                 when :gte
                  el_args[0].to_s.lit >= el_args[1].to_s.lit
                 when 'match-prefix'.to_sym
                  Sequel::SQL::StringExpression.like(el_args[0],"#{el_args[1]}%",case_insensitive: true)
                 when :regex
                  Sequel::SQL::StringExpression.like(el_args[0],Regexp.new(el_args[1]),case_insensitive: true)
                 when :oneof
                  SQL.in(el_args[0],el_args[1])
                 else
                  raise ErrorPatternNotImplemented.new(:comparison_op,el_op)
                end
              end
            end
            return nil if and_list.empty?
            case op
              when :and
                SQL.and(*and_list)
              when :or
                SQL.or(*and_list)
              else
                raise Error.new("unexpected operator #{op}")
            end
          end

          private

          def self.ret_eq_comparison(arg1,arg2)
            if arg2.is_a?(TrueClass)
              arg1
            elsif arg2.is_a?(FalseClass)
              SQL.not(arg1)
            else
              {arg1 => arg2}
            end
          end

          def self.ret_sequel_ds_with_relation(ds,search_pattern)
            relation = search_pattern.find_key(:relation)
            sql_tbl_name = DB.sequel_table_name(relation)
            unless sql_tbl_name
              Log.error("illegal relation given #{relation}")
              return nil
            end
            ds.from(sql_tbl_name)
          end

          def self.ret_sequel_ds_with_columns(ds,search_pattern,model_handle,remote_col_info=nil,vcol_sql_fns=nil)
            base_field_set = search_pattern.field_set()
            model_name = model_handle[:model_name]
            columns = base_field_set.cols
            return ds if columns.empty?

            # first prune out all non scalar real columns
            # TODO: make sure no side effects of thios switch
            # processed_field_set =  base_field_set.only_including(Model::FieldSet.all_real_scalar(model_name))
            processed_field_set = base_field_set.only_including(Model::FieldSet.all_real(model_name))

            # compute cols_to_add by looking at both local columns and ones that are in join conditions to enable remote columns to be joined in
            # do not have to worry about duplicates because with_added_cols will do that
            cols_to_add = []

            if remote_col_info and not remote_col_info.empty?
              cols_to_add_remote = remote_col_info.map do |r|
                qualified_col = r[:join_cond].values.first
                # strip off model_name__ prefix and discard non matching prefixes
                (qualified_col.to_s =~ Regexp.new('^(.+)__(.+)$')) ? ($1.to_sym == model_name ? $2.to_sym : nil) : qualified_col
              end.compact
              cols_to_add = cols_to_add + cols_to_add_remote
            end

            # this fn only adds real columns neededd by base_field set or vcol_sql_fns (vcols with alias processed in process_local_and_remote_dependencies
            cols_to_add_local = base_field_set.extra_local_columns(vcol_sql_fns)
            cols_to_add = cols_to_add + cols_to_add_local if cols_to_add_local

            processed_field_set = processed_field_set.with_added_cols(*cols_to_add)
            # always include id column
            processed_field_set.add_col!(:id)


            ds.select(*(processed_field_set.cols))
          end

          def self.ret_sequel_ds_with_filter(ds,sequel_filter)
            sequel_filter ? ds.where(sequel_filter) : ds
          end

          def self.ret_sequel_ds_with_order_by_and_paging(ds,search_pattern)
            order_by = search_pattern.find_key(:order_by)
            paging = search_pattern.find_key(:paging)
            DB.ret_paging_and_order_added_to_dataset(ds,order_by: order_by, paging: paging)
          end

          # return op in symbol form and args
          def self.get_op_and_args(expr)
            [expr.first,expr[1..expr.size-1]]
          end

          # it returns cols and also adds hash elements for vcolumns that have fn defs
          def self.get_filter_condition_op_and_args!(vcol_sql_fns,expr,model_handle)
            return get_op_and_args(expr) unless vcol_sql_fns
            new_vcol_sql_fns = has_virtual_column_with_fn_def?(expr,model_handle)
            return get_op_and_args(expr) unless new_vcol_sql_fns
            vcol_sql_fns.merge!(new_vcol_sql_fns)
            nil
          end

          # check if virtual column and if so substitute fn def if it exists
          def self.has_virtual_column_with_fn_def?(expr,model_handle)
            vcols = model_handle.get_virtual_columns()
            ret = {}
            expr[1..expr.size-1].each do |el|
              next unless el.is_a?(Symbol)
              next unless vcols[el]
              fn = vcols[el][:sql_fn]
              ret[el] = {sql_fn: fn, expr: expr}
            end
            ret.empty? ? nil : ret
          end

          class ErrorPatternNotImplemented < Error::NotImplemented
            def initialize(type,object)
              super("parsing item #{type} is not supported; it has form: #{object.inspect}")
            end
          end
        end
      end
    end
  end
end
