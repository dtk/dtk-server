module XYZ
  class PropagateProcessor
    #propgate from output var to input var
    def propagate()

      #TODO: debug
      puts "---------------------------"
      [:function,:function_index,:input_value,:input_semantic_type,:output_value,:output_semantic_type,:input_link_info].each do |x| 
        pp [x,eval(x.to_s)]
      end
      puts "---------------------------"
      #function 'eq' short circuited
      return {:value_derived => output_value_aux(), :link_info => nil} if function == "eq"
      hash_ret = 
        case function
         when "sap_config_ipv4" 
          propagate_when_sap_config_ipv4()
         when "host_address_ipv4"
          propagate_when_host_address_ipv4()
         when "select_one"
          propagate_when_select_one()
         when "eq_indexed"
          propagate_when_eq_indexed()
         when "sap_ipv4__sap_db" 
          propagate_when_sap_ipv4__sap_db()
         else
          raise ErrorNotImplemented.new("propagate value not implemented yet for fn #{function}")
        end
      hash_ret
    end

    def initialize(attr_link,input_attr,output_attr)
      @function = attr_link[:function]
      @function_index = attr_link[:function_index]
      @input_attr = input_attr
      @output_attr = output_attr
    end
   private

    #TODO: need to simplify so we dont need all these one ofs
    #function-specfic propagation
    def propagate_when_sap_config_ipv4()
      output_v = 
        if output_semantic_type().is_array? 
          raise ErrorNotImplemented.new("propagate_when_sap_config_ipv4 when output has empty list") if output_value.empty?
          output_value
        else
          [output_value]
        end

      value = nil
      if input_semantic_type().is_array?
        #cartesian product with host_address 
        #TODO: may simplify and use flatten form
        value = Array.new
        output_v.each do |sap_config|
          value += input_value.map{|input_item|sap_config.merge("host_address" => input_item["host_address"])}
        end
      else #not input_semantic_type().is_array?
        raise Error.new("propagate_when_sap_config_ipv4 does not support input scalar and output array with size > 1") if output_value.size > 1
        value = output_v.first.merge("host_address" => input_value["host_address"])
      end
      {:value_derived => value, :link_info => nil}
    end

    def propagate_when_sap_ipv4__sap_db()
      output_v = 
        if output_semantic_type().is_array? 
          raise ErrorNotImplemented.new("propagate_when_sap_ipv4__sap_db when output has empty list") if output_value.empty?
          output_value
        else
          [output_value]
        end

      value = nil
      if input_semantic_type().is_array?
        #cartesian product with host_address 
        #TODO: may simplify and use flatten form
        value = Array.new
        output_v.each do |sap_config|
          value += input_value.map{|input_item|sap_config.merge("host_address" => input_item["host_address"])}
        end
      else #not input_semantic_type().is_array?
        raise Error.new("propagate_when_sap_ipv4__sap_db does not support input scalar and output array with size > 1") if output_value.size > 1
        value = output_v.first.merge("host_address" => input_value["host_address"])
      end
      {:value_derived => value, :link_info => nil}
    end

    def propagate_when_host_address_ipv4()
      output_v = 
        if output_semantic_type().is_array? 
          raise ErrorNotImplemented.new("propagate_when_host_address_ipv4 when output has empty list") if output_value.empty?
          output_value
        else
          [output_value]
        end

      value = nil
      if input_semantic_type().is_array?
        #cartesian product with host_address 
        value = output_v.map{|host_address|input_value.map{|input_item|input_item.merge("host_address" => host_address)}}.flatten     
      else #not input_semantic_type().is_array?
        raise Error.new("propagate_when_host_address_ipv4 does not support input scalar and output array with size > 1") if output_value.size > 1
        value = output_v.first.merge("host_address" => input_value["host_address"])
      end
      {:value_derived => value, :link_info => nil}
    end

    def propagate_when_select_one()
      raise ErrorNotImplemented.new("propagate_when_select_one when input has more than one elements") if output_value() and output_value().size > 1
      {:value_derived => output_value ? output_value().first : nil, :link_info => nil}
    end

    def propagate_when_eq_indexed()
      link_info = input_link_info()
      array_pointers = link_info.array_pointers(function_index)
      new_rows = output_value().nil? ? [nil] : (output_semantic_type().is_array? ?  output_value() : [output_value()])
      value = nil
      if array_pointers.nil?
        value = (input_value||[]) + new_rows
        link_info.update_array_pointers!(function_index,((input_value||[]).size...value.size).to_a)
      else
        unless array_pointers.size == new_rows.size
          raise ErrorNotImplemented.new("propagate_when_eq_indexed when number of rows spliced in changes")
        end
        value = Array.new
        new_rows_index = 0
        #replace rows in array_pointers with new_rows
        input_value.each_with_index do |row,i|
          if array_pointers.include?(i)
            value << new_rows[new_rows_index]
            new_rows_index += 1
          else
            value << row
          end
        end
      end
Debug.print_and_ret(
      {:value_derived => value,:link_info => link_info.hash_value}
)
    end

    #########instance var access fns
    attr_reader :function,:function_index
    def input_value()
      @input_value ||= @input_attr[:value_derived]
    end
    def input_semantic_type()
      @input_semantic_type ||= SemanticType.create_from_attribute(@input_attr)
    end
    def input_link_info()
      return @input_link_info if @input_link_info 
      link_info = @input_attr[:link_info]
      return nil unless link_info
      @input_link_info = link_info.kind_of?(Attribute::LinkInfo) ? link_info : Attribute::LinkInfo.new(link_info)
    end
    def output_value()
      @output_value ||= output_value_aux()
    end
    def output_value_aux()
      @output_attr[:value_asserted]||@output_attr[:value_derived]
    end
    def output_semantic_type()
      @output_semantic_type ||= SemanticType.create_from_attribute(@output_attr)
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
      "sap_config_ipv4" => {
        "port" =>  {:required => true, :type => :integer},
        "protocol" => {:required => true, :type => :string},
        "binding_addr_constraints" => {:type => :json}
      },
      "sap_ipv4" => {
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
      "sap_socket" => {
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
      "sap_config_ipv4" => {
      },
      "sap_ipv4" => {
        :external => true,
        :port_type => "output"
      },
      "sap_ref" => {
        :external => true,
        :port_type => "input"
      },
      "sap_socket" => {
      },
      "db_info" => {
#        :external => true,
      }
    }
  end
end
