require 'sequel'
module XYZ
  ##relies on Sequel overwriting ~ | and &
  #TODO: maybe otehr syntax to get around problems with these characters in ruby 1.9
  module SQL
    ## Booelan expressions 
    def self.not(x)
      return nil if x.nil?
      ~x
    end
    def self.in(col,array)
      {col => array}
    end
    def self.or(*args)
      ret = nil
      args.reverse.each{|x|ret = or_aux(x,ret)}
      ret
    end
    def self.and(*args)
      ret = nil
      args.reverse.each{|x|ret = and_aux(x,ret)}
      ret
    end
    #takes into accout a or b can be null
    def self.not_equal(a,b)
      SQL.or(SQL.not(a => b),
             SQL.and({a => nil},SQL.not(b => nil)),
             SQL.and({b => nil},SQL.not(a => nil)))
    end

    #####
    ##### Sequel functions and column refs
    def self.now()
      :NOW.sql_function
    end

    def self.aliased_expression(expr,aliaz)
      Sequel::SQL::AliasedExpression.new(expr,aliaz)
    end

    module ColRef
      #block contains expression that is evaluated to array; each element but last is pair [condition,val]; last is "elee value
      def self.case(&block)
        case_array = block.call(self)
        else_case = case_array.pop
        case_array.case(else_case)
      end
      def self.concat(*args,&block)
        #TODO: make sure to_a does not have side effect like falttening hashs inside
        return block.call(self).sql_string_join if block
        return String.new if args.empty? 
        args.sql_string_join
      end
      def self.coalesce(*args)
        #translates to case when not arg[0] is null then  arg[0] ... else null end
        args.map{|x|[~{x => nil},x]}.case(nil)
      end
      def self.sum(x,y)
        x.to_s.lit + y
      end

      def self.max(arg=nil,&block)
        return max(block.call(self)) if block
        :Max.sql_function(arg)
      end
      def self.qualified_ref()
        [:ref,[[{:ref_num => nil},""]].case(["-",:ref_num.cast(:text)].sql_string_join)].sql_string_join
      end
    end

    ######
    #Objects that get translated to sql terms when being processed in a db/data_processing fn
    class SetIfUnset 
      def initialize(val)
        @val = val
      end
      def to_sequel(col,sql_operation)
        #sql_operation will be :update or :insert
        sql_operation == :update ? SQL::ColRef.coalesce(col,@val) : @val
      end
    end
    ######
    module WhereCondition
      def self.like(l,r)
        Sequel::SQL::StringExpression.like(l,r)
      end

    end
   private
    def self.or_aux(x,y)
      return y if x.nil? or (x.kind_of?(Hash) and x.empty?)
      return x if y.nil? or (y.kind_of?(Hash) and y.empty?)
      x | y
    end
    def self.and_aux(x,y)
      return y if x.nil? or (x.kind_of?(Hash) and x.empty?)
      return x if y.nil? or (y.kind_of?(Hash) and y.empty?)
      x & y
    end

    module DatatsetGraphMixin
      #for debugging
      def ppsql()
        @sequel_ds.sql.gsub(/"/,'')
      end

      attr_reader :model_name_info, :sequel_ds
      def graph(join_type,right_ds,join_conditions=true,opts={})
        new_model_name_info = right_ds.model_name_info.first.create_unique(@model_name_info,opts[:table_alias])
        model_name_info = @model_name_info + [new_model_name_info]
        table_alias = new_model_name_info.ret_qualified_model_name()
        #TODO: think can make more efficient by adding in :select => [cols.]] for the rs table; without that it looks like sequel making a db call to find relevant columns for join result
        sequel_graph = @sequel_ds.graph(right_ds.sequel_ds,join_conditions,opts.merge(:join_type => join_type, :table_alias => table_alias))
        Graph.new(sequel_graph,model_name_info,@c)
      end

      #have this in addition to where because special processing of column
      def where_column_equal(col,value)
        #substitue in virtual col fn if it exists
        vcol_info = ((DB_REL_DEF[model_name]||{})[:virtual_columns]||{})[col]
        return where(col => value) unless vcol_info
        raise Error.new("virtual column #{col} cannot appear in where clause unless it has a fn def") unless vcol_info[:sql_fn]
        where(vcol_info[:sql_fn] => value)
      end

     private
      def model_name()
        model_name_info.first.model_name
      end
    end

    module FilterPostProcessingMixin 
      def add_filter_post_processing(filter)
        raise ErrorPostProcFilterNotImpl.new(:filter,filter) unless (filter.kind_of?(Array) and filter.first == :and)
        filter_fn = filter[1..filter.size-1].map{|expr|parse_expression(expr)}.join(" and ")
        @filter_post_processing = lambda{|obj|eval(filter_fn)}
      end
     private
      def parse_expression(expr)
        raise ErrorPostProcFilterNotImpl.new(:expression,expr) unless expr.kind_of?(Array) and expr.size == 3 
        case expr[0]
         when :eq
          "(#{parse_term(expr[1])} == #{parse_term(expr[2])})"
         when "match-prefix".to_sym
          "(#{parse_term(expr[1])} =~ Regexp.new('^#{expr[2]}'))"
         else
          raise ErrorPostProcFilterNotImpl.new(:operation,expr[0])
        end
      end
      def parse_term(x)
        if x.kind_of?(Symbol) 
          "obj[:#{x}]" 
        elsif x.kind_of?(String)
          '"'+x+'"'
        elsif x.kind_of?(Numeric)
          x
        elsif x.kind_of?(TrueClass)
          true
        elsif x.kind_of?(FalseClass)
          false
        else
          raise Error.new("Unexpected term in post processing filter #{x.inspect}")
        end
      end
      class ErrorPostProcFilterNotImpl < ErrorNotImplemented
        def initialize(type,obj)
          super("filter_post_processing with #{type} #{obj.inspect}")
        end
      end
    end

    class ModelNameInfo 
      attr_reader :model_name,:ref_num
      def initialize(model_name,ref_num=1,model_name_alias=nil)
        @model_name = model_name.to_sym
        @ref_num = ref_num
        @model_name_alias = model_name_alias
      end
      def ret_qualified_model_name()
        @model_name_alias || (@ref_num == 1 ? @model_name : "#{@model_name}#{@ref_num.to_s}").to_sym
      end
      def create_unique(existing_name_info,model_name_alias=nil)
        #check whether model_name is in existing_name_info if so bump up by 1
        new_ref_num =  1 + (existing_name_info.find_all{|x|x.model_name == @model_name}.map{|y|y.ref_num}.max || 0)
        ModelNameInfo.new(@model_name,new_ref_num,model_name_alias)
      end
    end

    class Dataset
      include DatatsetGraphMixin
      include FilterPostProcessingMixin 
      #TODO: needed to fully qualify Dataset; could this constraint be removed? by chaging expose?
      post_hook = "lambda{|x|XYZ::SQL::Dataset.new(model_handle,x,@filter_post_processing)}"
      expose_methods_from_internal_object :sequel_ds, %w{where select from_self}, :post_hook => post_hook
      expose_methods_from_internal_object :sequel_ds, %w{sql}
      def initialize(model_handle,sequel_ds,filter_post_processing=nil)
        @model_name_info = [ModelNameInfo.new(model_handle[:model_name])]
        @sequel_ds = sequel_ds
        @c = model_handle[:c]
        @filter_post_processing = filter_post_processing
      end

      def join_table(join_type,right_ds,join_conditions=true,opts={})
        sequel_join = @sequel_ds.join_table(join_type,right_ds.sequel_ds,join_conditions,opts)
        model_handle = ModelHandle.new(@c,:join_table)
        Dataset.new(model_handle,sequel_join)
      end

      def add_virtual_column_aliases(vcol_values)
        vcol_aliases = vcol_values.map{|vc|{vc[:value] => vc[:column]}}
        Dataset.new(model_handle,@sequel_ds.select(*@sequel_ds.columns + vcol_aliases))
      end

      def paging_and_order(opts)
        any_change = {}
        sequel_ds = DB.ret_paging_and_order_added_to_dataset(@sequel_ds,opts,any_change)
        return self unless any_change[:changed]
        Dataset.new(model_handle(),sequel_ds)
      end

      def all()
        ret = ArrayObject.new
        @sequel_ds.all.map do |row|
          Model.process_raw_db_row!(row,model_name)
          new_row = DB_REL_DEF[model_name][:model_class].new(row,@c,model_name)
          next if @filter_post_processing and not @filter_post_processing.call(new_row)
          ret << new_row
        end
        ret
      end

      def model_handle()
        ModelHandle.new(@c,model_name)
      end

    end

    #creates a table dataset from rows, which is array with each element being a hash; each row has same keys
    class ArrayDataset < Dataset
      def self.create(db,rows,model_handle,opts={})
        return nil if rows.empty?
        if opts[:convert_for_update] or opts[:convert_for_create]
          sql_operation = opts[:convert_for_update] ? :update : :create
          modify_for_partial_values!(rows,db,model_handle) if opts[:partial_value] and sql_operation == :update
          rows.each{|row| db.convert_from_object_to_db_form!(model_handle,row,sql_operation)}
        end
        ArrayDataset.new(db,rows,model_handle)
      end
     private
      def self.modify_for_partial_values!(rows,db,model_handle)
        #need to get values if there are any json columns being updated and update value is array or hash
        db_rel = DB_REL_DEF[model_handle[:model_name]]
        cols_to_get = rows.first.reject{|k,v|not ((v.kind_of?(Hash) or v.kind_of?(Array)) and db.json_table_column?(k,db_rel))}.keys
        return nil if cols_to_get.empty?
        unless rows.first.has_key?(:id)
          Log.error("partial value processing can only be handled when id is on each row")
          return nil
        end
        where_clause = SQL.in(:id,rows.map{|r|r[:id]})
        objects = db.get_objects_scalar_columns(model_handle,where_clause,Model::FieldSet.opt(cols_to_get+[:id],model_handle[:model_name]))
        indexed_rows = rows.inject({}){|h,r|h.merge(r[:id] => r)}
        objects.each do |object|
          id = object[:id]
          (object.keys-[:id]).each do |k| 
            Aux.merge_into_json_col!(object,k,indexed_rows[id][k])
            indexed_rows[id][k] = object[k]
          end
        end
      end
      
      def initialize(db,rows,model_handle)
        raise Error.new("ArrayDataset.new called with rows being empty") if rows.empty?
        aliaz = model_handle[:model_name]
        empty_sequel_ds = db.empty_dataset()
        sequel_ds = nil
        if db.respond_to?(:ret_array_dataset)
          sequel_ds = db.ret_array_dataset(rows)
        else
          rows.each do |row|
            sequel_select = empty_sequel_ds.select(*row.map{|x|{x[1] => x[0]}})
            sequel_ds = sequel_ds ? sequel_ds.union(sequel_select,{:all => true}) : sequel_select
          end
        end
        super(model_handle,sequel_ds.from_self({:alias => aliaz}))
      end
    end
    class Graph
      include DatatsetGraphMixin
      include FilterPostProcessingMixin 
      #TODO: needed to fully qualify Dataset; could this constraint be removed? by chaging expose?
      expose_methods_from_internal_object :sequel_ds, %w{where select from_self}, :post_hook => "lambda{|x|XYZ::SQL::Graph.new(x,@model_name_info,@c,@filter_post_processing)}"
      expose_methods_from_internal_object :sequel_ds, %w{sql}
      def initialize(sequel_ds,model_name_info,c,filter_post_processing=nil)
        @sequel_ds = sequel_ds
        @model_name_info = model_name_info
        @c = c
        @filter_post_processing = filter_post_processing
      end

      def paging_and_order(opts)
        any_change = {}
        sequel_ds = DB.ret_paging_and_order_added_to_dataset(@sequel_ds,opts,any_change)
        return self unless any_change[:changed]
        Graph.new(sequel_ds,@model_name_info,@c)
      end

      def add_virtual_column_aliases(vcol_values)
        graph_aliases = vcol_values.inject({}){|h,vc|h.merge(vc[:column] => [model_name,vc[:column],vc[:value]])}
        Graph.new(@sequel_ds.add_graph_aliases(graph_aliases),@model_name_info,@c)
      end

      def all()
        #TODO may be more efficient if flatten by use something like Model.db.db[@sequel_ds.sql].all
        # this avoids needing to reanchor each from primary table (which should be bulk of info
        #alterantive look at capability of Sequel to pass in row processing block

        #pull first element from under top level key
        primary_model_name = @model_name_info.first.model_name() 
        rest_model_indexes = @model_name_info[1..@model_name_info.size-1]
        ret = ArrayObject.new
        @sequel_ds.all.each do |row|
          primary_cols = row.delete(primary_model_name)
          Model.process_raw_db_row!(primary_cols,primary_model_name)
          primary_cols.each{|k,v|row[k] = v}
          rest_model_indexes.each do |m|
            model_index = m.ret_qualified_model_name()
            next unless row[model_index]
            Model.process_raw_db_row!(row[model_index],m.model_name)
          end
          new_row = DB_REL_DEF[primary_model_name][:model_class].new(row,@c,primary_model_name)
          next if @filter_post_processing and not @filter_post_processing.call(new_row)
          ret << new_row
        end
        ret
      end
    end
  end  
end
