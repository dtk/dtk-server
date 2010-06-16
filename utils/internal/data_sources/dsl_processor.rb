module XYZ
  module DataTranslationClassMixin
    #can class vars 
    def class_rules()
      @class_rules ||= DBUpdateHash.create_with_auto_vivification()
    end
    
    def top_level_completeness_constraints() 
      @top_level_completeness_constraints ||= nil
    end
    def set_entire_target_is_complete(constraints={})
      @top_level_completeness_constraints = constraints
    end

   private

    def definitions(&block)
      context = Context.new(self,:no_conditions)
      context.instance_eval(&block) 
      class_rules.freeze
    end
  end
  class Context
    attr_reader :relation,:condition
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
      Function.new(func_name_or_def,args)
    end

    def source_complete_for_entire_target(constraints={})
      @parent.set_entire_target_is_complete(constraints)
    end

    def definition(item)
      Definition.new(item)
    end

    def source_complete_for(trgt,constraints=nil)
      trgt.mark_as_complete(constraints)
    end
    def ==(x)
      @relation == x.relation and @condition == x.condition
    end

    def class_rules()
      @parent.class_rules
    end

    def evaluate_condition(source_obj)
      return true if @relation == :no_conditions
      return @condition.apply(source_obj) if @relation == :if_exists
      raise Error.new("condition #{relation} does not exist")
    end
  end

  class NestedDefinition
    def initialize(obj_type,source_attributes)
      @obj_type = obj_type
      @source_attributes = source_attributes
    end
    def normalize(source_obj,parent_ds_object)
      #TBD: how to avoid this db call
      ds_object = parent_ds_object.get_directly_contained_objects(:data_source_entry,{:obj_type=>@obj_type.to_s}).first
      ds_adapter = ds_object ? ds_object.ds_object_adapter : nil
      raise Error.new("cannot find data source adapter for nested definition") if ds_adapter.nil?
      #TBD: need to set appropriate flags on whetehr golden store
      ret = DBUpdateHash.new()
      @source_attributes.apply(source_obj).each do |ref,attrs|
        #TBD: just test how to deal with ref
        key = ds_adapter.relative_distinguished_name(attrs,ref)
        ret[key] = ds_adapter.normalize(attrs)
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

    def [](a)
      @path << a
      self
    end

    def apply(source_obj)
      HashObject.nested_value(source_obj,@path)
    end
  end

  class ForeignKey < String
    def initialize(uri)
      replace(uri)
    end
  end

  class Function
    def initialize(func_name_or_def,*args)
      if func_name_or_def.kind_of?(String) or func_name_or_def.kind_of?(Symbol)
        @function_name = func_name_or_def.to_sym
      else #should be a lambda function
        @function_ref = func_name_or_def
      end
      @args = args.first
    end
      
    def apply(source_obj)
      evaluated_args = @args.map{|term|apply_to_term(term,source_obj)}
      if @function_name 
        send(@function_name,*evaluated_args)
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
    def apply_to_term(term,source_obj)
      if term.kind_of?(Source)
        term.apply(source_obj)
      elsif term.kind_of?(Function)
        term.apply(source_obj)
      elsif term.kind_of?(Definition)
        apply_to_term(term.item,source_obj)
      else
        term
      end
    end
  end
end

