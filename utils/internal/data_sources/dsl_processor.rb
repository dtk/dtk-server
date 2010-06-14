module XYZ
  module DataTranslationClassMixin
    #Should be overwritten if no dsl
    def normalize(source_obj)
      target_obj = DBUpdateHash.create_with_auto_vivification()
      class_rules.each do |condition,top_level_assign|
        top_level_assign.each do |attr,assign,constraints|
          if condition.evaluate_condition(source_obj)
            self.process_assignment(target_obj,attr,assign,constraints,source_obj) 
          end
        end
      end
      target_obj
    end

    def evaluate_condition(condition)
    end

    def process_assignment(target_obj,attr,assign,constraints,source_obj) 
      if assign.kind_of?(Source)
        target_obj[attr] = assign.apply(source_obj)
      elsif assign.kind_of?(Function)
        target_obj[attr] = assign.apply(source_obj)
      elsif assign.kind_of?(ForeignKey)
        target_obj[Object.assoc_key(attr)] = assign
      elsif assign.kind_of?(Hash)
        assign.each do |nested_attr,nested_assign,nested_constraints|
          process_assignment(target_obj[attr],nested_attr,nested_assign,nested_constraints,source_obj)
        end
      else
       target_obj[attr] = assign
      end
      target_obj.set_constraints(constraints) if constraints
    end


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

    class Source 
      def initialize()
        @path = Array.new
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
        else
          term
        end
      end
    end
  end
end

