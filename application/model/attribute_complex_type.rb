#TODO: just stubbing now with cached hashes
module XYZ
  class AttributeComplexType < Model
    set_relation_name(:attribute,:complex_type)
    def self.up()
    end
    #helper fns
    def self.has_required_fields_given_semantic_type?(obj,semantic_type)
      pattern =  SchemaPattern.create_from_semantic_type(semantic_type)
      return nil unless pattern
      has_required_fields?(obj,pattern)
    end

    def self.flatten_attribute_list(attr_list)
      ret = Array.new
      attr_list.each do |attr|
        value = attr[:attribute_value]
        if value.nil? or not attr[:data_type] == "json"
          ret << attr 
        else
          nested_type_pat = SchemaPattern.create_from_semantic_type(attr[:semantic_type])
          if nested_type_pat
            top_level=true
            flatten_attribute!(ret,value,attr,nested_type_pat,top_level)
          else 
            ret << attr
          end
        end
      end
      ret
    end

   private

    def self.has_required_fields?(value_obj,pattern)
      #care must be taken to make this three-valued
      if pattern.is_atomic?()
        has_required_fields_when_atomic?(value_obj,pattern)
      elsif pattern.is_array?()
        has_required_fields_when_array?(value_obj,pattern)
      else
        has_required_fields_when_hash?(value_obj,pattern)
      end
    end

    def self.has_required_fields_when_atomic?(value_obj,pattern)
      (not pattern[:required]) or not value_obj.nil?
    end

    def self.has_required_fields_when_array?(value_obj,pattern)
      unless value_obj.kind_of?(Array)
        Log.error("mismatch between object #{value_obj.inspect} and pattern #{pattern.inspect}")
        return nil
      end
      array_body_pat, can_be_empty = pattern.parse_array()
      return false if ((not can_be_empty) and value_obj.empty?)
      value_obj.each do |el|
        ret = has_required_fields?(el,array_body_pat)
        return ret unless ret.kind_of?(TrueClass)
      end
      true
    end

    def self.has_required_fields_when_hash?(value_obj,pattern)
      unless value_obj.kind_of?(Hash)
        Log.error("mismatch between object #{value_obj.inspect} and pattern #{pattern.inspect}")
        return nil
      end

      pattern.each do |k,child_pat|
        el = value_obj[k.to_sym]
        ret = has_required_fields?(el,child_pat)
        return ret unless ret.kind_of?(TrueClass) 
      end
      true
    end

    #TODO: add "index that will be used to tie unravvled attribute back to the base object and make sure
    #base object in the attribute
    def self.flatten_attribute!(ret,value_obj,attr,pattern,top_level=false)
      if pattern.nil?
        flatten_attribute_when_nil_pattern!(ret,value_obj,attr,top_level)
      elsif pattern.is_atomic?()
        flatten_attribute_when_atomic_pattern!(ret,value_obj,attr,pattern,top_level)
      elsif value_obj.kind_of?(Array)
        flatten_attribute_when_array!(ret,value_obj,attr,pattern,top_level)
      elsif value_obj.kind_of?(Hash)
        flatten_attribute_when_hash!(ret,value_obj,attr,pattern,top_level)
      else
        flatten_attribute_when_mismatch!(ret,value_obj,attr,pattern,top_level)
      end
      nil
    end


    def self.flatten_attribute_when_nil_pattern!(ret,value_obj,attr,top_level)
      if attr[:data_type] == "json" and top_level
        ret << attr
      else
        ret << attr.merge(:attribute_value => value_obj,:data_type => "json")
      end    
      nil
    end

    def self.flatten_attribute_when_atomic_pattern!(ret,value_obj,attr,pattern,top_level)
      if attr[:data_type] == pattern[:type].to_s and top_level
        ret << attr
      else
        ret << attr.merge(:attribute_value => value_obj,:data_type => pattern[:type].to_s)
      end    
      nil
    end

    def self.flatten_attribute_when_array!(ret,value_obj,attr,pattern,top_level)
      array_pat = pattern[:array]
      return flatten_attribute_when_mismatch!(ret,value_obj,attr,pattern,top_level) unless array_pat

      if value_obj.empty? 
        ret << (top_level ? attr : attr.merge(:attribute_value => value_obj))
        return nil
      end

      value_obj.each_with_index do |child_val_obj,i|
        child_attr = attr.merge(:display_name => "#{attr[:display_name]}[#{i.to_s}]")
        flatten_attribute!(ret,child_val_obj,child_attr,array_pat)
      end
      nil
    end


    #TODO: shoudl we iterate over missiing keys pattern.keys - val_obj.keys)
    def self.flatten_attribute_when_hash!(ret,value_obj,attr,pattern,top_level)
      return flatten_attribute_when_mismatch!(ret,value_obj,attr,pattern,top_level) if pattern[:array]
      value_obj.each do |k,child_val_obj|
        child_attr = attr.merge(:display_name => "#{attr[:display_name]}[#{k}]")
        child_pattern = pattern[k.to_s]
        flatten_attribute!(ret,child_val_obj,child_attr,child_pattern)
      end
      nil
    end

    def self.flatten_attribute_when_mismatch!(ret,value_obj,attr,pattern,top_level)
      Log.error("mismatch between object #{value_obj.inspect} and pattern #{pattern}")
      ret << (top_level ? attr : attr.merge(:attribute_value => value_obj))
      nil
    end
    class SchemaPattern < HashObject
      def self.create_from_attribute(attr)
        semantic_type = attr[:semantic_type]
        return nil unless semantic_type
        key = semantic_type_key(semantic_type)
        return ComplexTypeSchema[key] if ComplexTypeSchema[key]
        return create_from_semantic_type(semantic_type) if semantic_type.kind_of?(Hash)
      end

      def self.create_from_semantic_type(semantic_type)
        return nil unless semantic_type
        key = semantic_type_key(semantic_type)
        return ComplexTypeSchema[key] if ComplexTypeSchema[key]

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
      def is_array?()
        #TODO: may have :array+ and :array* to distingusih whether array can be empty
        keys.first == :array
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
        if ComplexTypeSchema[key]
          ret[index] = ComplexTypeSchema[key]
        elsif semantic_type.kind_of?(Hash)
          ret_schema_from_semantic_type_aux!(ret[index],key,semantic_type.values.first)        
        else
          ret[index] = {:type => "json"}
        end
      end

      ComplexTypeSchema = self.new( 
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
  end
end
