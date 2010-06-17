module XYZ
  module DSNormalizer
    class Top
      class << self
        #filter applied when into put in ds_attribute bag gets overwritten for non trivial filter
        def filter(ds_hash)
          ds_hash
        end

        def class_rules()
        @class_rules ||= DBUpdateHash.create_with_auto_vivification()
       end
     private

      def definitions(&block)
        context = Context.new(self,:no_conditions)
        context.instance_eval(&block) 
        class_rules.freeze
      end
    end
  end
  class Context
    attr_reader :relation,:condition, :parent
    def initialize(parent,relation=:no_condition,condition=nil)
      @parent = parent
      @relation = relation
      @condition = condition 
    end
    #top level "conditionals"
    def if_exists(condition,&block)
      context = Context.new(self,:if_exists,condition)
      context.instance_eval(&block) 
    end
    #sub commands
    def target()
      matching_cond_index = class_rules.keys.find{|cond|cond == self}
      class_rules[matching_cond_index || self]
    end

    def nested_definition(obj_type,source_attributes)
      target[obj_type] = NestedDefinition.new(obj_type,source_attributes)
    end

    def foreign_key(uri)
      ForeignKey.new(uri)
    end

    def source()
      Source.new()
    end

    def fn(func_name_or_def,*args)
      Function.new(func_name_or_def,args,self)
    end

    def definition(item)
      Definition.new(item)
    end

    def source_complete_for(trgt,constraints={})
      trgt.mark_as_complete(constraints)
    end

    def source_key()
      Function.new(lambda{|x|x.keys.first},[Source.new()],self)
    end

    def ==(x)
      @relation == x.relation and @condition == x.condition
    end

    def class_rules()
      @parent.class_rules
    end

    def evaluate_condition(ds_hash)
      return true if @relation == :no_conditions
      return @condition.apply(ds_hash) if @relation == :if_exists
      raise Error.new("condition #{relation} does not exist")
    end
  end

  class NestedDefinition
    def initialize(obj_type,source_attributes)
      @obj_type = obj_type
      @source_attributes = source_attributes
    end
    def normalize(ds_hash_list,parent_ds_object)
      #TBD: how to avoid this db call
      ds_object = parent_ds_object.get_directly_contained_objects(:data_source_entry,{:obj_type=>@obj_type.to_s}).first
      raise Error.new("cannot find data source adapter for nested definition") if ds_object.nil?
      #TBD: need to set appropriate flags on whetehr golden store
      ret = DBUpdateHash.new()
      @source_attributes.apply(ds_hash_list).each do |ref,attrs|
        child_source_hash = {ref => attrs}        
        key = ds_object.relative_distinguished_name(child_source_hash)
        ret[key] = ds_object.normalize(child_source_hash)
      end
      ret
    end
  end    

  #TBD: is there a better way to do this
  #motivation for putting this in is to avoid having to have var = ..source.; var,dup in all refs 
  # because if haev two references to same source they "would update each otehr without this
  class Definition
    attr_reader :item
    def initialize(item)
      @item = item
    end
    def [](a)
     item.kind_of?(Source) ? item.dup[a] : item[a]
    end
  end

  class Source 
    def initialize(path=nil)
      @path = path ? Array.new(path) : Array.new
    end

    def dup() 
      self.class.new(@path)
    end

    def [](a="*")
      @path << a
      self
    end

    def apply(ds_hash)
      HashObject.nested_value(ds_hash,@path)
    end
  end

  class ForeignKey < String
    def initialize(uri)
      replace(uri)
    end
  end

  class Function
    def initialize(func_name_or_def,args,context_parent)
      if func_name_or_def.kind_of?(String) or func_name_or_def.kind_of?(Symbol)
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
        #resolve with respect class adapter
        #TBD: where do we put "wired" fns; can put it in DSNormalizerTop if using this path below
        @context_parent.parent.send(@function_name,*evaluated_args)
      elsif @function_ref
        @function_ref.call(*evaluated_args)
      end
    end
    #predefined functions
    def foreign_key(uri)
      #stub
      "*" + uri
    end
   private
    def apply_to_term(term,ds_hash)
      if term.kind_of?(Source)
        term.apply(ds_hash)
      elsif term.kind_of?(Function)
        term.apply(ds_hash)
      elsif term.kind_of?(Definition)
        apply_to_term(term.item,ds_hash)
      else
        term
      end
    end
  end
end
end

