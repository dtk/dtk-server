module XYZ
  ##relies on Sequel overwriting ~ | and &
  #TODO: maybe otehr syntax to get around problems with these characters in ruby 1.9
  module SQL
    ## Booelan expressions
    def self.not(x)
      return nil if x.nil?
      ~x
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

    ##### Sequel functions
    #coalesce returns first non null
    def self.coalesce(*args)
      #translates to case when not arg[0] is null then  arg[0] ... else null end
      args.map{|x|[~{x => nil},x]}.case(nil)
    end

    ######
    #Objects that get translated to sql terms when being processed in a db/data_processing fn
    class SetIfUnset 
      def initialize(val)
        @val = val
      end
      def to_sequel(col,sql_operation)
        #sql_operation will be :update or :insert
        sql_operation == :update ? SQL.coalesce(col,@val) : @val
      end
    end
    #####
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
      attr_reader :model_name_info, :sequel_ds
      def graph(join_type,right_ds,join_conditions)
        new_model_name_info = right_ds.model_name_info.first.create_unique(@model_name_info)
        model_name_info = @model_name_info + [new_model_name_info]
        table_alias = new_model_name_info.ret_qualified_model_name()
        sequel_graph = @sequel_ds.graph(right_ds.sequel_ds,join_conditions,{:join_type => join_type, :table_alias => table_alias})
        Graph.new(sequel_graph,model_name_info,@c)
      end
    end

    class ModelNameInfo 
      attr_reader :model_name,:ref_num
      def initialize(model_name,ref_num=1)
        @model_name = model_name.to_sym
        @ref_num = ref_num
      end
      def ret_qualified_model_name()
        (@ref_num == 1 ? @model_name : "#{@model_name}#{@ref_num.to_s}").to_sym
      end
      def create_unique(existing_name_info)
        #check whether model_name is in existing_name_info if so bump up by 1
        new_ref_num =  1 + (existing_name_info.find_all{|x|x.model_name == @model_name}.map{|y|y.ref_num}.max || 0)
        ModelNameInfo.new(@model_name,new_ref_num)
      end
    end

    class Dataset
      include DatatsetGraphMixin
      #TODO: needed to fully qualify Dataset; could this constraint be removed? by chaging expose?
      post_hook = "lambda{|x|XYZ::SQL::Dataset.new(model_handle,x)}"
      expose_methods_from_internal_object :sequel_ds, %w{where}, :post_hook => post_hook
      expose_methods_from_internal_object :sequel_ds, %w{sql}
      def initialize(model_handle,sequel_ds)
        @model_name_info = [ModelNameInfo.new(model_handle[:model_name])]
        @sequel_ds = sequel_ds
        @c = model_handle[:c]
      end

      def all()
        ret = ArrayObject.new
        @sequel_ds.all.map do |row|
          Model.process_raw_db_row!(row,model_name)
          ret << DB_REL_DEF[model_name][:model_class].new(row,@c,model_name)
        end
        ret
      end

     private
      def model_name()
        model_name_info.first.model_name
      end
      def model_handle()
        ModelHandle.new(@c,model_name)
      end
    end

    class Graph
      include DatatsetGraphMixin
      #TODO: needed to fully qualify Dataset; could this constraint be removed? by chaging expose?
      expose_methods_from_internal_object :sequel_ds, %w{where select}, :post_hook => "lambda{|x|XYZ::SQL::Graph.new(x,@model_name_info,@c)}"
      expose_methods_from_internal_object :sequel_ds, %w{sql}
      def initialize(sequel_ds,model_name_info,c)
        @sequel_ds = sequel_ds
        @model_name_info = model_name_info
        @c = c
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
          ret << DB_REL_DEF[primary_model_name][:model_class].new(row,@c,primary_model_name)
        end
        ret
      end
    end
  end  
end
