module XYZ
  class PropagateProcessor
    class Output < HashObject
    end
    class OutputArraySlice < Output
    end

    #propgate from output var to input var
    def propagate()
      #function 'eq' short circuited
      return {:value_derived => output_value_aux(), :link_info => nil} if function == "eq"
      hash_ret = 
        case function
         when "sap_config__l4" 
          propagate_when_sap_config__l4()
         when "host_address_ipv4"
          propagate_when_host_address_ipv4()
         when "select_one"
          propagate_when_select_one()
         when "eq_indexed"
          propagate_when_eq_indexed()
         when "sap_conn__l4__db" 
          propagate_when_sap_conn__l4__db()
         when "sap_config_conn__db"
          propagate_when_sap_config_conn__db()
         else
          raise ErrorNotImplemented.new("propagate value not implemented yet for fn #{function}")
        end
      hash_ret.kind_of?(Output) ? hash_ret : Output.new(hash_ret)
    end

    def initialize(attr_link,input_attr,output_attr)
      @function = attr_link[:function]
      @function_index = attr_link[:function_index]
      @input_attr = input_attr
      @output_attr = output_attr
    end
   private

    #TODO: need to simplify so we dont need all these one ofs
    #######function-specfic propagation
    #TODO: refactor to use  ret_cartesian_product()
    def propagate_when_sap_config__l4()
      output_v = 
        if output_semantic_type().is_array? 
          raise ErrorNotImplemented.new("propagate_when_sap_config__l4 when output has empty list") if output_value.empty?
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
#TODO: euqivalent changes may be needed on other cartesion products: removing this for below          value += input_value.map{|input_item|sap_config.merge("host_address" => input_item["host_address"])}
          value += input_value.map{|iv|iv["host_address"]}.uniq.map{|addr|sap_config.merge("host_address" => addr)}
        end
      else #not input_semantic_type().is_array?
        raise Error.new("propagate_when_sap_config__l4 does not support input scalar and output array with size > 1") if output_value.size > 1
        value = output_v.first.merge("host_address" => input_value["host_address"])
      end
      {:value_derived => value, :link_info => nil}
    end

    #TODO: refactor to use  ret_cartesian_product()
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

    def propagate_when_sap_conn__l4__db()
      ret_cartesian_product()
    end

    def propagate_when_sap_config_conn__db
      ret_cartesian_product()
    end

    def propagate_when_select_one()
      raise ErrorNotImplemented.new("propagate_when_select_one when input has more than one elements") if output_value() and output_value().size > 1
      {:value_derived => output_value ? output_value().first : nil, :link_info => nil}
    end

    def propagate_when_eq_indexed()
      #TODO: in transition; get rid of need to put in :derived_value
      array_pointers = Attribute::LinkInfo.array_pointers(@input_attr,function_index)
      new_rows = output_value().nil? ? [nil] : (output_semantic_type().is_array? ?  output_value() : [output_value()])
      value = nil
      if new_indexes_to_add = array_pointers.nil? ?  true : false
        value = (input_value||[]) + new_rows
        array_pointers = Attribute::LinkInfo.update_array_pointers!(@input_attr,function_index,(Array(input_value||[]).size...value.size))
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
    OutputArraySlice.new(:indexes => array_pointers, :array_slice => new_rows, :new_indexes_to_add => new_indexes_to_add, :link_info => @input_attr[:link_info], :value_derived => value)
#      {:value_derived => value,:link_info => @input_attr[:link_info]}
    end

=begin
    def propagate_when_eq_indexed()
      #TODO: in transition; get rid of need to put in :derived_value
      array_pointers = Attribute::LinkInfo.array_pointers(@input_attr,function_index)
      new_rows = output_value().nil? ? [nil] : (output_semantic_type().is_array? ?  output_value() : [output_value()])
      value = nil
      if new_indexes_to_add = array_pointers.nil? ?  true : false
        value = (input_value||[]) + new_rows
        array_pointers = Attribute::LinkInfo.update_array_pointers!(@input_attr,function_index,(Array(input_value||[]).size...value.size))
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
    OutputArraySlice.new(:indexes => array_pointers, :array_slice => new_rows, :new_indexes_to_add => new_indexes_to_add, :link_info => @input_attr[:link_info], :value_derived => value)
#      {:value_derived => value,:link_info => @input_attr[:link_info]}
    end

=end
    ###### helper fns for propagation fns
    def ret_cartesian_product()
      output_v = 
        if output_semantic_type().is_array? 
          raise ErrorNotImplemented.new("cartesian_product when output has empty list") if output_value.empty?
          output_value
        else
          [output_value]
        end

      value = nil
      if input_semantic_type().is_array?
        value = Array.new
        output_v.each do |sap_config|
          value += input_value.map{|input_item|input_item.merge(sap_config)}
        end
      else #not input_semantic_type().is_array?
        raise Error.new("cartesian_product does not support input scalar and output array with size > 1") if output_value.size > 1
        value =  input_value.merge(output_v.first)
      end
      {:value_derived => value, :link_info => nil}
    end

    #########instance var access fns
    attr_reader :function,:function_index
    def input_value()
      @input_value ||= @input_attr[:value_derived]
    end
    def input_semantic_type()
      @input_semantic_type ||= SemanticType.create_from_attribute(@input_attr)
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
    def is_hash?()
      not (is_array?() or is_atomic?())
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
      elsif  (not output_sem_type.is_array?) and (not input_sem_type.is_array?)
        "eq"
      else
        raise ErrorNotImplemented.new("find_link_function for input #{input_sem_type.inspect} and output #{output_sem_type.inspect}")
      end
    end

    #TODO: think problem is that output may not have rows yet oir may expand so better solution would be to set index map at same time that propagating variable -> need to make this atomic too or maybe this gives us chance to do a transaction where input variable and link's index map updated within a transaction"
    def self.find_index_map_and_input_attr_updates(input_attr,output_attr)
      ret = [nil,{}]
      return ret unless input_attr[:semantic_type_object].is_array?
      output_size = (output_attr[:attribute_value]||[]).size
      if output_size == 0
        Log.error("output_size == 0 is unexepected")
        return ret
      end
      input_size = (input_attr[:attribute_value]||[]).size
      index_map = (0..output_size-1).map do |i|
        {:output => [i], :input => [i+input_size]}
      end
      #TODO: use the 'transaction version' that augments arrays
      value_derived = (input_attr[:attribute_value]||[]) + null_values(output_attr[:attribute_value])
#      [index_map,{:id => input_attr[:id], :value_derived => value_derived}]
      [index_map,{}]
    end

    def is_atomic?()
      nil
    end
   private

    def self.null_values(item)
      if item.kind_of?(Array)
        item.map{|x|null_values(x)}
      elsif item.kind_of?(Hash)
        item.inject({}){|h,kv|h.merge(kv[0] => null_values(kv[1]))}
      else
        nil
      end
    end

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

  #TODO: for input ports may just have constraints, not syntax
  module AttributeSemantic
    #TODO: rather than external may have :internal_only
    Info =
      #L4 Saps adn sockets
      {
      "sap_config__l4" => {
        :syntax => {
          "port" =>  {:required => true, :type => :integer},
          "protocol" => {:required => true, :type => :string},
          "binding_addr_constraints" => {:type => :json}
        }
      },
      "sap__l4" => {
        :external => true,
        :port_type => "output",
        :has_port_object => true,
        :syntax =>  {
          "port" => {:required => true, :type => :integer},
          "protocol" => {:required => true, :type => :string},
          "host_address" => {:required => true, :dynamic => true, :type => :string}
        }
      },
=begin
rather than having or having two sap refs and user can remove or add to component
      "sap_ref__l4" => {
        :external => true,
        :port_type => "input", 
        :has_port_object => true,
        :syntax => { 
          :or => 
          [{
             "port" => {:required => true, :type => :integer},
             "protocol" => {:required => true, :type => :string},
             "host_address" => {:required => true, :type => :string}
           },
           {"socket_file" => {:required => true, :type => :string}}
          ]
        }
      },
=end
      "sap_ref__l4" => {
        :external => true,
        :port_type => "input", 
        :has_port_object => true,
        :syntax => { 
           "port" => {:required => true, :type => :integer},
           "protocol" => {:required => true, :type => :string},
           "host_address" => {:required => true, :type => :string}
        }
      },

      "sap__socket" => {
        :syntax => {
          "socket_file" => {:required => true, :type => :string}
        }
      },

      #DB params
      "db_config" => {
        :external => true,
        :port_type => "output",
        :syntax => {
          "database" => {:required => true, :type => :string},
          "username" => {:required => true, :type => :string},
          "password" => {:required => false, :type => :string}
        }
      },
      "db_params" => {
        :external => true,
        :port_type => "input"
      },
      "db_ref" => {
        :external => true,
        :port_type => "input"
      },

      #TODO: may deprecate below
      "sap_config__db" => {
      },
      "sap__db" => {
        :external => true,
        :port_type => "output"
      },
      "sap_ref__db" => {
        :external => true,
        :port_type => "input"
      },
    }
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
      if semantic_type.kind_of?(Hash)
        val = semantic_type.values.first
        return create_json_type() if val.kind_of?(Hash) and val.keys.first == :application
        ret_schema_from_semantic_type_aux!(ret,key,val)
      end
      return nil if ret.empty?
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
        ret[index] = create_json_type()
      end
    end

    def self.create_json_type()
      SemanticTypeSchema.new({:type => :json})
    end

    TranslationToSchema = self.new(AttributeSemantic::Info.inject({}){|h,kv|h.merge(kv[0] => kv[1][:syntax])},true)
  end
end
