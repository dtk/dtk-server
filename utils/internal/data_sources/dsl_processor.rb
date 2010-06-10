#TBD: temp for testing
require "../auxiliary.rb"
module XYZ
  class DSLTop
    def self.apply(source_obj)
      #TBD: ignoring conditions
      #TBD stub
      target_obj = Aux.create_auto_vivification_hash()
      class_rules.each do |cond,top_level_assign|
        top_level_assign.each do |attr,assign|
          self.process_assignment(target_obj,attr,assign,source_obj) 
        end
      end
      target_obj
    end

    def self.process_assignment(target_obj,attr,assign,source_obj) 
      if assign.kind_of?(Source)
        target_obj[attr] = assign.apply(source_obj)
      elsif assign.kind_of?(Function)
        target_obj[attr] = assign.apply(source_obj)
      elsif assign.kind_of?(Hash)
        assign.each do |nested_attr,nested_assign|
          process_assignment(target_obj[attr],nested_attr,nested_assign,source_obj)
        end
      else
       target_obj[attr] = assign
      end
    end

   private
    #top level "conditionals"
    def self.if_exists(condition,&block)
      context = self.new(Condition.new(:if_exists,condition))
      context.instance_eval(&block) 
    end

    def self.no_conditions(&block)
      context = self.new(Condition.new(:no_conditions))
      context.instance_eval(&block) 
    end

    #can appear in top level
    def self.source()
      Source.new()
    end

    #sub commands
    def target()
      matching_cond_index = class_rules.keys.find{|cond|cond == @condition}
      class_rules[matching_cond_index || @condition]
    end

    def source()
      self.class.source()
    end

    def fn(func_name_or_def,*args)
      Function.new(func_name_or_def,args)
    end
 
    ################
    #TBD: move to Aux

    def initialize(condition=nil)
      @condition = condition
    end

    def class_rules()
      self.class.class_rules
    end
    def self.class_rules()
      @class_rules ||= Aux.create_auto_vivification_hash()
    end
    
    class Condition
     attr_reader :relation,:condition
     def initialize(relation=:no_condition,condition=nil)
       @relation = relation
       @condition = condition 
     end

     def ==(x)
       @relation == x.relation and @condition == x.condition
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
        Aux.nested_value(source_obj,@path)
      end

      #TBD: just for debugging
      def to_s()
        "source[#{@path.join("][")}]"
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

#TBD: below is temporary test code
module XYZ
  class SampleLeafClass < DSLTop
    if_exists(source[:private_ip_address]) do
      target[:eth0][:type] = 'ethernet' 
      target[:eth0][:family] = 'ipv4' 
      target[:eth0][:address] =  source[:private_ip_address] 
      target[:test1] = fn(:test_fn,source[:private_ip_address],1,2)
      target[:test2] = fn(lambda{|x,y|x+y},source[:private_ip_address],1)
      target[:test3] = fn(lambda{|x,y|x+y},source[:private_ip_address],fn(:nested,1))
    end
    #debug statement to print the result of the pasring
    require 'pp'; pp class_rules
  end
  class Leaf2 < DSLTop
    no_conditions do
      target[:test4] = fn(:test_fn,source["foo"][:private_ip_address],1,2)
    end
   pp class_rules
  end
  class SampleLeafClass3 < DSLTop
    if_exists(source[:private_ip_address]) do
      target[:eth0][:type] = 'ethernet' 
      target[:eth0][:family] = 'ipv4' 
      target[:eth0][:address] =  source[:private_ip_address] 
      target[:a][:b][:c] = fn(lambda{|x,y|x+y},source[:count],4)
    end
  end
  pp "----------------------------"
  source_obj = {:private_ip_address => "10.22.2.3", :count => 8}
  pp SampleLeafClass3.apply(source_obj)
end
