module DTK; class Node
  class NodeAttribute
    class << self
      def attributes_hash()
        Def.ret_hash()
      end
    end

    class Def < Hash
      def initialize(canonical_name)
        super()
        merge!(:canonical_name => canonical_name)
      end
      def self.Attribute(canonical_attr_name,klass=nil,&block)
        @@index_by_canonical_name ||= Hash.new
        Add.new(@@index_by_canonical_name,canonical_attr_name,klass,&block)
        if klass
          #Interprted def is a node attribute that has additional methods defined on it
          (@@interpreted_def ||= Hash.new)[klass] = @@index_by_canonical_name[canonical_attr_name]
        end
      end

      def self.all_canonical_names()
        @@index_by_canonical_name.keys()
      end

      #index can be a canonical name or an interpretd object

      def self.names(canonical_name=nil)
        object(canonical_name).names()
      end
      def names()
        [self[:canonical_name]] + (self[:aliases]||[])
      end

     private    
      def self.object(canonical_name=nil)
        unless ret = (canonical_name ? @@index_by_canonical_name[canonical_name] : @@interpreted_def[self])
          index = canonical_name||self
          raise Error.new("Bad index given (#{index.inspect}")
        end
        ret
      end

      class Add < Hash
        def initialize(attrs,attr,klass=nil,&block)
          @attr = attr
          @attrs = attrs
          @klass = klass||Def
          instance_eval(&block)
          attrs[attr]
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

        def aliases(aliases)
          set_meta_property!(:aliases, aliases)
        end
        
        private
        def set_meta_property!(prop,val)
          (@attrs[@attr] ||= @klass.new(@attr))[prop] = val
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
=end
