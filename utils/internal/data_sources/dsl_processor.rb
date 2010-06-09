module XYZ
  class DSLTop
    #TBD: move to Aux
    #auto vivification trick from http://t-a-w.blogspot.com/2006/07/autovivification-in-ruby.html
    def self.create_auto_vivification_hash()
      Hash.new {|h,k| h[k] = Hash.new(&h.default_proc)}
    end
    def self.if_exists(condition,&block)
      context = self.new(Condition.new(:if_exists,condition))
      context.instance_eval(&block) 
    end

    def initialize(condition=nil)
      @condition = condition
    end

    def class_rules()
      self.class.class_rules
    end
    def self.class_rules()
      @class_rules
    end

    def target()
      class_rules[@condition]
    end

    def self.source()
      Source.new()
    end
    def source()
      self.class.source()
    end

    class Condition
     def initialize(relation=:no_condition,condition=nil)
       @relation = relation
       @condition = condition 
     end
    end

    class Source < String
      def initialize()
        replace('source')
      end

      def [](a)
        term = a.kind_of?(Symbol) ? ":#{a}" : "'#{a}'"
        replace("#{self}[#{term}]")
      end
    end
  end
end

#TBD: below is temporary test code
module XYZ
  class SampleLeafClass < DSLTop
    #TBD: see if way to use inherit or extend so dont need this in every leaf class
    @class_rules ||= create_auto_vivification_hash()
    if_exists(source[:private_ip_address]) do
      target[:eth0][:type] = 'ethernet' 
      target[:eth0][:family] = 'ipv4' 
      target[:eth0][:address] =  source[:private_ip_address] 
    end
    #debug statement to print the result of the pasring
    require 'pp'; pp class_rules
  end
  class Leaf2 < DSLTop
   pp class_rules
  end
  class SampleLeafClass < DSLTop
   pp class_rules
  end
end
