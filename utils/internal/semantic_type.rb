#TODO: change name from semantio type to convery deals with attribute Function Type
module DTK
  #TODO: may move PropagateProcessor under model/attribute_link
  class PropagateProcessor
    class Output < HashObject
    end
    class OutputArrayAppend < Output
    end
    class OutputPartial < Output
    end

    #propgate from output var to input var
    def propagate()
      #function 'eq' short circuited
      return {:value_derived => output_value_aux()} if function == "eq"
      hash_ret = 
        case function
         when "eq_indexed"
          propagate_when_eq_indexed()
         when "array_append"
          propagate_when_array_append()
          #TODO: may deprecate rest
         when "select_one"
          propagate_when_select_one()
         when "sap_config__l4" 
          propagate_when_sap_config__l4()
         when "host_address_ipv4"
          propagate_when_host_address_ipv4()
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
      @index_map = AttributeLink::IndexMap.convert_if_needed(attr_link[:index_map])
      @attr_link_id =  attr_link[:id]
      @input_attr = input_attr
      @output_attr = output_attr
      @input_path = attr_link[:input_path]
      @output_path = attr_link[:output_path]
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
      {:value_derived => value}
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
      {:value_derived => value}
    end

    def propagate_when_sap_conn__l4__db()
      ret_cartesian_product()
    end

    def propagate_when_sap_config_conn__db
      ret_cartesian_product()
    end

    def propagate_when_select_one()
      raise ErrorNotImplemented.new("propagate_when_select_one when input has more than one elements") if output_value() and output_value().size > 1
      {:value_derived => output_value ? output_value().first : nil}
    end

    #called when it is an equlaity setting between indexed values on input and output side. Can be the null index on one of the sides meaning to take whole value
    #TODO: can simplify because only will be called when input is not an array
    def propagate_when_eq_indexed()
      #TODO: may flag more explicitly if from create or propagate vars
      if @index_map.nil? and (@input_path.nil? or @input_path.empty?) and (@output_path.nil? or @output_path.empty?)
        new_rows = output_value().nil? ? [nil] : (output_semantic_type().is_array? ?  output_value() : [output_value()])
        OutputArrayAppend.new(:array_slice => new_rows, :attr_link_id => @attr_link_id)
      else
        index_map_persisted = @index_map ? true : false
        index_map = @index_map || AttributeLink::IndexMap.generate_from_paths(@input_path,@output_path)
        OutputPartial.new(:attr_link_id => @attr_link_id, :output_value => output_value, :index_map => index_map, :index_map_persisted => index_map_persisted)
      end
    end

    #called when input is an array and each link into it appends teh value in
    def propagate_when_array_append()
      #TODO: may flag more explicitly if from create or propagate vars
      if @index_map.nil? and (@input_path.nil? or @input_path.empty?)
        new_rows = output_value().nil? ? [nil] : (output_semantic_type().is_array? ?  output_value() : [output_value()])
        output_is_array = @output_attr[:semantic_type_object].is_array?()
        OutputArrayAppend.new(:array_slice => new_rows, :attr_link_id => @attr_link_id, :output_is_array => output_is_array)
      else
        index_map_persisted = @index_map ? true : false
        index_map = @index_map || AttributeLink::IndexMap.generate_from_paths(@input_path,nil)
        OutputPartial.new(:attr_link_id => @attr_link_id, :output_value => output_value, :index_map => index_map, :index_map_persisted => index_map_persisted)
      end
    end

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
      {:value_derived => value}
    end

    #########instance var access fns
    attr_reader :function
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

    #TODO: this needs to be fixed; this includes fixing up to handle inputs that are arrays of hashes
    def self.find_link_function(input_attr,output_attr)
      input_type = attribute_index_type__input(input_attr)
      output_type = attribute_index_type__output(output_attr)
      LinkFunctionMatrix[output_type][input_type]
    end
    #first index is output type, second one is input type
    LinkFunctionMatrix = {
      :scalar => {
        :scalar => "eq", :indexed => "eq_indexed", :array => "array_append"
      },
      :indexed => {
        :scalar => "eq_indexed", :indexed => "eq_indexed", :array => "array_append"
      },
      :array => {
        :scalar => "select_one", :indexed => "select_one", :array => "array_append"
      }
    }

    def is_atomic?()
      nil
    end

   private
    def self.attribute_index_type__input(attr)
      #TODO: think may need to look at data type inside array
      if attr[:input_path] then :indexed
      else attr[:semantic_type_object].is_array?() ? :array : :scalar
      end
    end

    def self.attribute_index_type__output(attr)
      #TODO: may need to look at data type inside array
      if attr[:output_path] then :indexed
      else attr[:semantic_type_object].is_array?() ? :array : :scalar
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

      "db_user_access" => {
        :external => true,
#TODO: need to rexamine use of :port_type => "input" in light of having attributes that can be read only vs read/write depending
#if they have alink; currently if marked as input then they are treated as readonly        
#        :port_type => "input",
        :syntax => {
          "username" => {:required => true, :type => :string},
          "password" => {:required => false, :type => :string},
          "inet_access" => {:required => true, :type => :boolean},
          "client_host_addr" => {:required => true, :type => :string}
        }
      },

      #TODO deprecate db ones in favor of above
      #DB params
      "db_config" => {
        :external => true,
        :port_type => "output",
        :syntax => {
          "database" => {:required => true, :type => :string},
          "username" => {:required => true, :type => :string},
          "password" => {:required => true, :type => :string}
        }
      },
      "db_params" => {
        :external => true,
        :port_type => "input",
        :syntax => {
          "database" => {:required => true, :type => :string},
          "username" => {:required => true, :type => :string},
          "password" => {:required => true, :type => :string}
        }
      },
      "db_ref" => {
        :external => true,
        :port_type => "input"
      },

      "service_check_input" => {
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

    def self.ret_scalar_defined_datatypes()
      TranslationToSchema.keys
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
