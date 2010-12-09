module XYZ
  class PropagateProcessor
    def propagate()
      #function 'eq' short circuited
      return {:derived_value => input_value_aux()} if function == "eq"
      #TODO: debug
      [:function,:function_index,:input_value,:input_semantic_type,:output_value,:output_semantic_type,:input_link_info].each do |x| 
        pp [x,eval(x.to_s)]
      end
      hash_ret = 
        case function
         when "sap_config[ipv4]" 
          propagate_when_sap_config_ipv4()
         when "select_one"
          propagate_when_select_one()
         when "eq_indexed"
          propagate_when_eq_indexed()
         else
          raise ErrorNotImplemented.new("propagate value not implemented yet for fn #{function}")
        end
      hash_ret.each{|k,v|hash_ret[k] = SerializeToJSON.serialize(v)}
      hash_ret
    end

    def initialize(attr_link,input_attr,output_attr)
      @function = attr_link[:function]
      @function_index = attr_link[:function_index]
      @input_attr = input_attr
      @output_attr = output_attr
    end
   private
    attr_reader :function,:function_index
    def input_value()
      @input_value ||= input_value_aux()
    end
    def input_value_aux()
      @input_attr[:value_asserted]||@input_attr[:value_derived]
    end
    def input_semantic_type()
      @input_semantic_type ||= SemanticType.create_from_attribute(@input_attr)
    end
    def input_link_info()
      @input_link_info ||= @input_attr[:link_info]
    end
    def output_value()
      @output_value ||= @output_attr[:value_derived]
    end
    def output_semantic_type()
      @output_semantic_type ||= SemanticType.create_from_attribute(@output_attr)
    end

    #function-specfic propagation
    def propagate_when_sap_config_ipv4()
      unless output_semantic_type().is_array? and input_semantic_type().is_array?
        raise ErrorNotImplemented.new("propagate_when_sap_config_ipv4 when both are not arrays")
      end
      #cartesian product with host_address 
      ret = Array.new
      input_value.each do |sap_config|
        ret += output_value.map{|output_item|sap_config.merge(:host_address => output_item[:host_address])}
      end
      {:value_derived => ret}
    end

    def propagate_when_select_one()
      raise ErrorNotImplemented.new("propagate_when_select_one when input has more than one elements") if input_value().size > 1
      {:value_derived => input_value().first}
    end

    def propagate_when_eq_indexed
      link_info = input_link_info()
      array_pointers = link_info.array_pointers(function_index)
      if array_pointers.nil?
        if output_value().nil?
          ret = (input_value||[]) + [nil]
          link_info.update_array_pointers!(function_index,[ret.size-1])
        else
          new_rows = output_semantic_type().is_array? ?  output_value() : [output_value()]
          ret = (input_value||[]) + new_rows
          link_info.update_array_pointers!(function_index,((input_value||[]).size...ret.size).to_a)
        end
Debug.print_and_ret(        {:value_derived => ret,:link_info => link_info.hash_value})
      else
        raise ErrorNotImplemented.new("propagate_when_eq_indexed when  array_pointers non null")
      end
    end
  end

  module CommonSemanticTypeMixin
    def is_array?()
      #TODO: may have :array+ and :array* to distinguish whether array can be empty
      keys.first == :array
    end
  end
  class SemanticType < HashObject
    include CommonSemanticTypeMixin
    def self.create_from_attribute(attr)
      semantic_type = attr[:semantic_type]
      return SemanticTypeSimple.new(semantic_type) unless semantic_type.kind_of?(Hash)

      self.new(convert_hash(semantic_type))
    end

    def self.find_link_function(input_sem_type,output_sem_type)
      #TODO: stub; should test byod is array whether types match
      if output_sem_type.is_array? and not input_sem_type.is_array?
        "select_one"
      elsif  output_sem_type.is_array? and input_sem_type.is_array?
        "eq_indexed"
      else
        raise raise ErrorNotImplemented.new("find_link_function for input #{input_sem_type.inspect} and output #{output_sem_type.inspect}")
      end
    end
   private
    def self.convert_hash(item)
      return item unless item.kind_of?(Hash)
      item.inject({}) do |h,kv|
        new_key = kv[0].to_s =~ /^:(.+$)/ ? $1.to_sym : kv[0].to_s
        h.merge(new_key =>  convert_hash(kv[1]))
      end
    end
  end
  class SemanticTypeSimple < SemanticType
    def initialize(val)
      @value = val
      super()
    end
    def is_array?()
      nil
    end
  end

  class SemanticTypeSchema < HashObject
    include CommonSemanticTypeMixin
    def self.create_from_attribute(attr)
      semantic_type = attr[:semantic_type]
      return nil unless semantic_type
      key = semantic_type_key(semantic_type)
      return TranslationToSchema[key] if TranslationToSchema[key]
      return create_from_semantic_type(semantic_type) if semantic_type.kind_of?(Hash)
    end
    
    def self.create_from_semantic_type(semantic_type)
      return nil unless semantic_type
      key = semantic_type_key(semantic_type)
      return TranslationToSchema[key] if TranslationToSchema[key]

      ret = create_with_auto_vivification()
      if  semantic_type.kind_of?(Hash)
        ret_schema_from_semantic_type_aux!(ret,key,semantic_type.values.first)
      end
      if ret.empty?
        Log.error("found semantic type #{semantic_type.inspect} that does not have a nested type definition")
        return nil
      end
      ret.freeze
    end

    def is_atomic?()
      has_key?(:type)
    end

    #returns [array_body_pattern, whether_can_be_empty]
    def parse_array()
      #TODO: may have :array+ and :array* to distingusih whether array can be empty
      [values.first,false]
    end

    private

    def self.semantic_type_key(semantic_type)
      ret = (semantic_type.kind_of?(Hash) ? semantic_type.keys.first : semantic_type).to_s
      ret == ":array" ? :array : ret
    end

    def self.ret_schema_from_semantic_type_aux!(ret,index,semantic_type)
      key = semantic_type_key(semantic_type)
      if TranslationToSchema[key]
        ret[index] = TranslationToSchema[key]
      elsif semantic_type.kind_of?(Hash)
        ret_schema_from_semantic_type_aux!(ret[index],key,semantic_type.values.first)        
      else
        ret[index] = SemanticType.new({:type => "json"})
      end
    end

    TranslationToSchema = self.new( 
    {
      "sap_config[ipv4]" => {
        "port" =>  {:required => true, :type => :integer},
        "protocol" => {:required => true, :type => :string},
        "binding_addr_constraints" => {:type => :json}
      },
      "sap[ipv4]" => {
        "port" => {:required => true, :type => :integer},
        "protocol" => {:required => true, :type => :string},
        "host_address" => {:required => true, :type => :string}
      },
      "sap_ref" => {
        :or => 
        [{
           "port" => {:required => true, :type => :integer},
           "protocol" => {:required => true, :type => :string},
           "host_address" => {:required => true, :type => :string}
         },
         {"socket_file" => {:required => true, :type => :string}}
        ]
      },
      "sap[socket]" => {
        "socket_file" => {:required => true, :type => :string}
      },
      
      "db_info" => {
        "username" => {:required => true, :type => :string},
        "database" => {:required => true, :type => :string},
        "password" => {:required => true, :type => :string}
      }
    },true)
  end

  module AttributeSemantic
    #TODO: rather than external may have :internal_only
    Info =
      {
      "sap_config[ipv4]" => {
      },
      "sap[ipv4]" => {
        :external => true,
        :port_type => "output"
      },
      "sap_ref" => {
        :external => true,
        :port_type => "input"
      },
      "sap[socket]" => {
      },
      "db_info" => {
#        :external => true,
      }
    }
  end
end
