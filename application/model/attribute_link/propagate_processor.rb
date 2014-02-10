#TODO: this needs a lot of cleanup
module DTK; class AttributeLink
  class PropagateProcessor
    class Output < HashObject
    end
    class OutputArrayAppend < Output
    end
    class OutputPartial < Output
    end

    #propagate from output var to input var
    def propagate()
      #function 'eq' short circuited
      return {:value_derived => output_value_aux()} if function == "eq"
      hash_ret = 
        if function.kind_of?(String)
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
          end
        elsif function.kind_of?(Hash) and function.has_key?(:function)
          propagate_when_function_specified(function[:function])
        end
      unless hash_ret
        raise Error::NotImplemented.new("propagate value not implemented yet for fn #{function}")
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
    def propagate_when_function_specified(function_def)
      if output_semantic_type().is_array? 
        raise Error::NotImplemented.new("specified functions not implemented when output is an array")
      end
      if input_semantic_type().is_array? 
        raise Error::NotImplemented.new("specified functions not implemented when input is an array")
      end

      computed_value = SpecifiedFunction.ret_computed_value(function_def,output_value)
      {:value_derived => computed_value}
    end
    
    class SpecifiedFunction
      def self.ret_computed_value(function_def,output_value)
        function_class(function_def).compute_value(function_def,output_value)
      end
     private
      def self.function_class(function_def)
        case function_def[:name].to_sym
          when :var_embedded_in_text then VarEmbeddedInText
          else raise Error.new("propagate value not implemented yet for #{function_def[:name]})")
        end
      end
                              
      class VarEmbeddedInText < self
        def self.compute_value(function_def,param)
          text_parts = function_def[:constants][:text_parts].dup
          ret = text_parts.shift
          text_parts.each do |text_part|
            ret << param
            ret << text_part
          end
          ret
        end
      end
    end

    #TODO: need to simplify so we dont need all these one ofs
    #######function-specfic propagation
    #TODO: refactor to use  ret_cartesian_product()
    def propagate_when_sap_config__l4()
      output_v = 
        if output_semantic_type().is_array? 
          raise Error::NotImplemented.new("propagate_when_sap_config__l4 when output has empty list") if output_value.empty?
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
          raise Error::NotImplemented.new("propagate_when_host_address_ipv4 when output has empty list") if output_value.empty?
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
      raise Error::NotImplemented.new("propagate_when_select_one when input has more than one elements") if output_value() and output_value().size > 1
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
          raise Error::NotImplemented.new("cartesian_product when output has empty list") if output_value.empty?
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
end; end
