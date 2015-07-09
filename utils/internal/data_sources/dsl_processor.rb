module XYZ
  module DSNormalizer
    class Top
      # filter applied when into put in ds_attribute bag gets overwritten for non trivial filter
      def self.filter_raw_source_objects(ds_hash)
        ds_hash
      end

      # default unique_key; can be overwritten
      def self.unique_keys(ds_hash)
        [relative_distinguished_name(ds_hash)]
      end

      def self.class_rules
        @class_rules ||= DBUpdateHash.create()
      end

      def self.name_delimiter
        Model::Delim::Common
      end

      private

      def self.definitions(&block)
        context = Context.new(self,:no_conditions)
        context.instance_eval(&block)
        class_rules.freeze
      end
    end
   class Context
     attr_reader :relation,:condition, :parent
     def initialize(parent,relation=:no_condition,condition=nil)
       @parent = parent
       @relation = relation
       @condition = condition
     end

     # top level "conditionals"
     def if_exists(condition,&block)
       context = Context.new(self,:if_exists,condition)
       context.instance_eval(&block)
     end
     # sub commands
     def target
       matching_cond_index = class_rules.keys.find{|cond|cond == self}
       class_rules[matching_cond_index || self]
     end

     def nested_definition(obj_type,source_attributes)
       target[obj_type] = NestedDefinition.new(obj_type,source_attributes)
     end

     # TBD: need to fix; need to determine if use source attribute path, target attribute path and/or source ds_key to refer to foreign key
     def foreign_key(obj_type,path)
       ForeignKey.new(fn(lambda{|source|"/#{obj_type}/#{source}"},path))
     end

     def source
       Source.new()
     end

     def if_unset(arg)
       SetIfUnset.new(arg,self)
     end

     def fn(func_name_or_def,*args)
       Function.new(func_name_or_def,args,self)
     end

     def source_complete_for(trgt,constraints={})
       trgt.mark_as_complete(constraints)
     end

     def source_key
       Function.new(lambda{|x|x.keys.first},[Source.new()],self)
     end

     def ==(x)
       @relation == x.relation && @condition == x.condition
     end

     def class_rules
       @parent.class_rules
     end

     def evaluate_condition(ds_hash)
       return true if @relation == :no_conditions
       return @condition.has_path?(ds_hash) if @relation == :if_exists
       raise Error.new("condition #{relation} does not exist")
     end

    def column_names(model_name)
      DB_REL_DEF[model_name][:columns].keys
    end
   end

   class NestedDefinition
     def initialize(obj_type,source_attributes)
       @obj_type = obj_type
       @source_attributes = source_attributes
     end

     def normalize(ds_hash_list,parent_ds_object)
       # TBD: how to avoid this db call
       ds_object = parent_ds_object.get_directly_contained_objects(:data_source_entry,obj_type: @obj_type.to_s).first
       raise Error.new("cannot find data source adapter for nested definition for #{@obj_type}") if ds_object.nil?
       ret = DBUpdateHash.new()
       (@source_attributes.apply(ds_hash_list)||{}).each do |ref,child_source_hash_x|
         child_source_hash = child_source_hash_x.merge(ref: ref)
         key = ds_object.relative_distinguished_name(child_source_hash)
         ret[key] = ds_object.normalize(child_source_hash)
       end
       ret.mark_as_complete if ds_object[:ds_is_golden_store]
      ret
    end
  end

  class Source
    def initialize(path=nil)
      @path = path ? Array.new(path) : []
    end

    def [](a='*')
      self.class.new(@path +[a])
    end

    def apply(hash)
      HashObject.nested_value(hash,@path)
    end

    def has_path?(hash)
      HashObject.has_path?(hash,@path)
    end
  end

  class ForeignKey
    attr_reader :arg
    def initialize(arg)
      @arg = arg
    end
  end

  class Function
    def initialize(func_name_or_def,args,context_parent)
      if func_name_or_def.is_a?(String) || func_name_or_def.is_a?(Symbol)
        @function_name = func_name_or_def.to_sym
      else #should be a lambda function
        @function_ref = func_name_or_def
      end
      @args = args
      @context_parent = context_parent
    end

    def apply(ds_hash)
      evaluated_args = @args.map{|term|apply_to_term(term,ds_hash)}
      if @function_name
        # resolve with respect class adapter
        # TODO: where do we put "wired" fns; can put it in DSNormalizerTop if using this path below
        # TODO: hack to handle when fn eval under if context
        if @context_parent.parent.respond_to?(@function_name)
          @context_parent.parent.send(@function_name,*evaluated_args)
        else
          @context_parent.parent.parent.send(@function_name,*evaluated_args)
        end
      elsif @function_ref
        @function_ref.call(*evaluated_args)
      end
    end

    private

    def apply_to_term(term,ds_hash)
      if term.is_a?(Source)
        term.apply(ds_hash)
      elsif term.is_a?(Function)
        term.apply(ds_hash)
      elsif term.is_a?(SQL::SetIfUnset)
        term
      else
        term
      end
    end
  end

  class SetIfUnset < Function
    def initialize(arg,context_parent)
      super(lambda{|arg|SQL::SetIfUnset.new(arg)},[arg],context_parent)
    end
  end
end
end
