#TODO: initially scaffolds SemanticType then will remove semantic type
#TODO: initially form sap from sap config then move to model where datatype has dynamic attribute that gets filled in
module DTK
  module AttributeDatatype
    def self.ret_datatypes()
      scalar_types = SemanticTypeSchema.ret_scalar_defined_datatypes()
      scalar_types += ret_builtin_scalar_types()
      ret = Array.new
      scalar_types.each do |t|
        ret << t
        ret << "array(#{t})"
      end
      ret
    end

    def ret_datatype()
      st_summary = self[:semantic_type_summary]
      return self[:data_type] unless st_summary
      is_array? ? "array(#{st_summary})" : st_summary
    end

    def ret_default_info()
      default = self[:value_asserted]
      return nil unless default
      #TODO: temparily unraveling arrays
      if is_array?()
        ret = Hash.new
        hash_semantic_type = semantic_type[:array]
        default.each_with_index do |d,i|
          el = ret_default_info__hash(hash_semantic_type,d)
          el.each{|k,v|ret.merge!("#{k}[#{i.to_s}]" => v)}
        end
        ret
      else
        ret_default_info__hash(semantic_type,default)
      end
    end

    def self.convert_value_to_ruby_object(attr)
      string_val = attr[:value_asserted]
      return nil if string_val.nil?
      case (attr[:data_type]||"string")
        when "string" 
          string_val
        when "boolean"
          case string_val
            when "true" then true
            when "false" then false
            else raise Error.new("Unexpected Boolean value (#{string_val})")
          end
        when "integer"
          if string_val =~ /^[0-9]+$/
            string_val.to_i
          else 
            raise Error.new("Unexpected Integer value (#{string_val})")
          end
        else 
          raise Error.new("Unexpected Datatype (#{attr[:data_type]})")
      end
    end 

    def self.attr_def_to_internal_form(hash)
      ret = Hash.new
      #check if it is an array
      #TODO: stub fn to check if array
      datatype = hash[:datatype]
      return ret unless datatype
      is_array = nil
      if datatype =~ /^array\((.+)\)$/
        datatype = $1
        is_array = true
      end
      if ret_builtin_scalar_types().include?(datatype)
        ret[:data_type] = datatype
      else
        ret[:data_type] = "json"
        ret[:semantic_type_summary] = datatype
        ret[:semantic_type] = is_array ? {":array".to_sym => datatype} : datatype
      end
      ret
    end

    def self.default()
      "string"
    end

   private
    def self.ret_builtin_scalar_types()
      [
       "string",
       "integer",
       "boolean"
      ]
    end

    def ret_default_info__hash(hash_semantic_type,default)
      hash_semantic_type.inject({}) do |h,(k,v)|
        if v[:dynamic]
          h
        else
          info = Hash.new
          info.merge!(:required=> v[:required]) if v.has_key?(:required)
          info.merge!(:type => v[:type])
          info.merge!(:default_value => default[k]) if default.has_key?(k)
          h.merge(k => info)
        end
      end
    end

    def semantic_type()
      @semantic_type ||= SemanticTypeSchema.create_from_attribute(self)
    end
    def is_array?()
      semantic_type().is_array?
    end
  end
end
