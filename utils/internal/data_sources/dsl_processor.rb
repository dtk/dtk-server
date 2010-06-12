module XYZ
  module DataTranslationClassMixin
    def apply(source_obj)
      #TBD: ignoring conditions
      #TBD stub
      target_obj = DBUpdateHash.create_with_auto_vivification()
      class_rules.each do |cond,top_level_assign|
        top_level_assign.each do |attr,assign,constraints|
          self.process_assignment(target_obj,attr,assign,constraints,source_obj) 
        end
      end
      target_obj
    end

    def process_assignment(target_obj,attr,assign,constraints,source_obj) 
      target_attr = target_obj[attr]
      if assign.kind_of?(Source)
        target_obj[attr] = assign.apply(source_obj)
      elsif assign.kind_of?(Function)
        target_obj[attr] = assign.apply(source_obj)
      elsif assign.kind_of?(ForeignKey)
        target_attr = target_obj[Object.assoc_key(attr)] = assign
      elsif assign.kind_of?(Hash)
        assign.each do |nested_attr,nested_assign,nested_constraints|
          process_assignment(target_obj[attr],nested_attr,nested_assign,nested_constraints,source_obj)
        end
      else
       target_obj[attr] = assign
      end
      if constraints
        target_obj[attr].set_constraints(constraints) 
      end
    end

    #can appear in top level 
    def source()
      Source.new()
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
        @parent.source()
      end

      def fn(func_name_or_def,*args)
        Function.new(func_name_or_def,args)
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
=begin
  module DataTranslationInstanceMixin
    ################
    def initialize(condition=nil)
      @condition = condition
    end
  end
=end
end

=begin
#TBD: below is temporary test code
module XYZ
  class  Ec3NodeInstance < DSLTop
    no_conditions do
      #TBD: allow source_complete_for to be top level; related to multiple conditionals poiting to same element
      source_complete_for target, :ds_source => :instance
      target[:eth0][:type] = 'ethernet' 
      target[:eth0][:family] = 'ipv4' 
      target[:eth0][:address] =  source[:private_ip_address] 
    end
    if_exists(source[:ip_address]) do
      #TBD: may introduce (use term scope or prefix) c
      # scope[:address_access_point] do 
      #   target[:type] = "internet"
      # end
      source_complete_for target[:address_access_point]

      prefix = target["internet_ipv4"][:address_access_point]
      prefix[:type] = "internet"
      prefix[:ip_address][:family] = "ipv4"
      prefix[:ip_address][:address] = source[:ip_address]
      #TBD: may allow form foreign_key[prefix] = "/network_partition/internet"
      foreign_key["internet_ipv4"][:address_access_point][:network_partition_id] = "/network_partition/internet"
    end
    require 'pp' ; pp class_rules
    pp "----------------------------"
    source_obj = {:private_ip_address => "10.22.2.3", :ip_address => "64.95.15.1"}
    pp apply(source_obj)
  end
end
=end
