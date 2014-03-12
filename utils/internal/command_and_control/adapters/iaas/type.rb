module DTK
  #This is the interpereter for the DSL to declare attributes for each iaas type
  #The example syntax is

=begin
DTK::IAAS.Type :ec2 do
  attribute :a1 do
    types [:a,:b,:c] #type could be an array of legal values
    description 'just a test'
  end
  attribute :b1 do
    types lambda{|x|x.kind_of?(Fixnum) and x > 10} #type could be a lambda that returns true if the argument is a legal value
  end
end
=end

#you will want to alter the meta information you store

# just do ruby type.rb to see how one can declare and use teh dsl
  class IAAS
    def self.Type(type,&block)
      @types ||= Hash.new 
      @types[type] = Type.new(type,&block)
    end
    def self.hash(type)
      @types[type]
    end
    class Type < Hash
      def initialize(type,&block)
        @type = type
        instance_eval(&block)
      end
      def attribute(attr,&block)
        attrs = self[:attributes] ||= Hash.new
        Attribute.new(attrs,attr,&block)
      end
    end
    class Attribute < Hash
      def initialize(attrs,attr,&block)
        @attr = attr
        @attrs = attrs
        instance_eval(&block)
      end
      def types(type_description)
        #for types has a lambda function that if true means the value is legal; if in dsl user gives array we convert this to lambda function
        lambda_fn = 
          if type_description.kind_of?(Array)
            lambda{|x|type_description.include?(x)}
          else #assume is a lambda fn
            type_description
          end
        set_meta_property!(:is_type?,lambda_fn)
      end

      #probably dont need this, but included to show how we include otehr meta fields
      def description(description)
        set_meta_property!(:description,description)
      end

      private
       def set_meta_property!(prop,val)
        (@attrs[@attr] ||= Hash.new)[prop] = val
       end
    end
  end
end

#TODO: move this to seperate file under ec2.rb that gets included by ec2
#Example declaration
DTK::IAAS.Type :ec2 do
  attribute :a1 do
    types [:a,:b,:c]
    description 'just a test'
  end
  attribute :b1 do
    types lambda{|x|x.kind_of?(Fixnum) and x > 10}
  end
end
require 'pp'
#this returns the full hash capturing the meta properties that we wil use to describe ec2 node attributes
hash = DTK::IAAS.hash(:ec2)
pp hash

#showing example of using the generated :is_type? content to check different attribute values
a_check = hash[:attributes][:a1][:is_type?]
pp [:a,:b,:d,:c].map{|y|{y => a_check.call(y)}}
b_check = hash[:attributes][:b1][:is_type?]
pp [:a,1,20,4].map{|y|{y => b_check.call(y)}}
