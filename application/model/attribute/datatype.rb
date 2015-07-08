module DTK; class Attribute
  module DatatypeMixin
    def ret_datatype
      unless st_summary = self[:semantic_type_summary]
        self[:data_type]
      else
        is_array?() ? "array(#{st_summary})" : st_summary
      end
    end

    def ret_default_info
      default = self[:value_asserted]
      return nil unless default
      if is_array?()
        ret = {}
        hash_semantic_type = semantic_type[:array]
        default.each_with_index do |d,i|
          el = ret_default_info__hash(hash_semantic_type,d)
          el.each{|k,v|ret.merge!("#{k}[#{i}]" => v)}
        end
        ret
      else
        Datatype.ret_default_info__hash(semantic_type,default)
      end
    end

    def convert_value_to_ruby_object
      update_object!(:data_type,:value_asserted,:value_derived)
      Datatype.convert_value_to_ruby_object(self)
    end

    private

    def semantic_type
      @semantic_type ||= SemanticTypeSchema.create_from_attribute(self)
    end

    def is_array?
      semantic_type().is_array?()
    end
  end

  module Datatype
    def self.ret_datatypes
      scalar_types = SemanticTypeSchema.ret_scalar_defined_datatypes()
      scalar_types += ret_builtin_scalar_types()
      ret = []
      scalar_types.each do |t|
        ret << t
        ret << "array(#{t})"
      end
      ret
    end

    def self.datatype_from_ruby_object(obj)
      if obj.is_a?(TrueClass) || obj.is_a?(FalseClass)
        "boolean"
      elsif obj.is_a?(Fixnum)
        "integer"
      elsif obj.is_a?(Hash) || obj.is_a?(Array)
        "json"
      else
        "string"
      end
    end

    def self.convert_value_to_ruby_object(attr,opts={})
      attr_val_field = opts[:value_field]||:attribute_value
      raw_val = attr[attr_val_field]
      return nil if raw_val.nil?
      case (attr[:data_type]||"string")
        when "string"
          raw_val
        when "boolean"
          case raw_val.to_s
            when "true" then true
            when "false" then false
            else raise_error_msg("boolean",raw_val,attr)
          end
        when "integer"
          if raw_val =~ /^[0-9]+$/
            raw_val.to_i
          else
            raise_error_msg("integer",raw_val,attr)
          end
        when "json"
          # will be converted already
          raw_val
        else
        raise Error.new("Unexpected Datatype (#{attr[:data_type]}) for attribute (#{attr.print_form()})")
      end
    end

    def self.attr_def_to_internal_form(hash)
      ret = {}
      # check if it is an array
      # TODO: stub fn to check if array
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

    def self.ret_default_info__hash(hash_semantic_type,default)
      hash_semantic_type.inject({}) do |h,(k,v)|
        if v[:dynamic]
          h
        else
          info = {}
          info.merge!(required: v[:required]) if v.key?(:required)
          info.merge!(type: v[:type])
          info.merge!(default_value: default[k]) if default.key?(k)
          h.merge(k => info)
        end
      end
    end

    def self.default
      "string"
    end

    private

    def self.raise_error_msg(type,val,attr)
      val_print_form = (val.respond_to?(:to_s) ? val.to_s : val.inspect)
      raise ErrorUsage.new("Unexpected #{type.to_s.capitalize} Value (#{val_print_form}) for attribute (#{attr.print_form}); use set-attribute to change its value")
    end

    def self.ret_builtin_scalar_types
      [
       "string",
       "integer",
       "boolean"
      ]
    end
  end
end; end
