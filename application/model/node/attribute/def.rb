module DTK; class Node
  class NodeAttribute
    class Def
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

        def required(required_boolean_val)
          set_meta_property!(:required, required_boolean_val)
        end
        
        def read_only(read_only_boolean_val)
          set_meta_property!(:read_only, read_only_boolean_val)
        end
        
        def is_port(port_boolean_val)
          set_meta_property!(:is_port, port_boolean_val)
        end
        
        def cannot_change(cannot_change_boolean_val)
          set_meta_property!(:cannot_change, cannot_change_boolean_val)
        end
        
        def data_type(data_type_val)
          set_meta_property!(:data_type, data_type_val)
        end
        
        def default_value(default_value)
          set_meta_property!(:value_asserted, default_value)
        end
        
        def semantic_type_summary(semantic_type_summary_val)
          set_meta_property!(:semantic_type_summary, semantic_type_summary_val)
        end
        
        def dynamic(dynamic_val)
          set_meta_property!(:dynamic, dynamic_val)
        end
        
        def hidden(hidden_val)
          set_meta_property!(:hidden, hidden_val)
        end
        
        def semantic_type(semantic_type_val)
          set_meta_property!(:semantic_type, semantic_type_val)
        end
        
        private
        def set_meta_property!(prop,val)
          (@attrs[@attr] ||= Hash.new)[prop] = val
        end
      end
    end
  end
end; end



=begin
    class Def 
    def self.attribute_fields(type)
      IAAS.hash(:ec2)[:attributes].inject(Hash.new) do |h,(name,attr_def)|
        #to prune out meta fields from ones that are fields on attribiute object
        attr_fields_asserted = Aux.hash_subset(attr_def,AttributeFields)
        attr_fields = Fields.new(attr_def[:types]).merge(:display_name => name.to_s).merge(attr_fields_asserted)
        h.merge(name => attr_fields)
      end
    end
    AttributeFields = [:display_name,:required,:read_only,:is_port,:cannot_change,:data_type,:dynamic,:hidden,:semantic_type,:semantic_type_summary,:value_asserted]
    class Fields < Hash
      def initialize(types)
        @types = types
      end
    end
  end
#TODO: move this to seperate file under ec2.rb that gets included by ec2
#Example declaration
# DTK::IAAS.Type :ec2 do
#   attribute :a1 do
#     types [:a,:b,:c]
#     description 'just a test'
#   end
#   attribute :b1 do
#     types lambda{|x|x.kind_of?(Fixnum) and x > 10}
#   end
# end
# require 'pp'
#this returns the full hash capturing the meta properties that we wil use to describe ec2 node attributes
# hash = DTK::IAAS.hash(:ec2)
# pp hash

#showing example of using the generated :is_type? content to check different attribute values
# a_check = hash[:attributes][:a1][:is_type?]
# pp [:a,:b,:d,:c].map{|y|{y => a_check.call(y)}}
# b_check = hash[:attributes][:b1][:is_type?]
# pp [:a,1,20,4].map{|y|{y => b_check.call(y)}}

=end


