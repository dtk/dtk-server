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

    NumericIndexDelimiter = "__indx:"
    NumericIndexRegexp = Regexp.new("#{NumericIndexDelimiter}([0-9]+$)")
    IDDelimiter = "__id:"
    def self.item_path_token_array(attr)
      return nil unless attr[:item_path]
      attr[:item_path].map{|indx| indx.kind_of?(Numeric) ? "#{NumericIndexDelimiter}#{indx.to_s}" : indx.to_s} 
    end
    def self.container_id(type,id)
      return nil if id.nil?
      "#{IDDelimiter}#{type}:#{id.to_s}"
    end

    def self.unravel_raw_post_hash(raw_post_hash)
      #TODO: case on model; assuming now it is node and looking for top level components
      type = :component
      ret = Array.new
      unravel_raw_post_hash_top_level!(ret,raw_post_hash,type)
      ret
    end

   private
    def self.unravel_raw_post_hash_top_level!(ret,hash,type,parent_id=nil)
      pattern = Regexp.new("^#{IDDelimiter}#{type}:([0-9]+$)")
      hash.each do |k,child_hash|
        id = (k =~ pattern; $1 ? $1.to_i : nil)
        next unless id
        if type == :component
          unravel_raw_post_hash_top_level!(ret,child_hash,:attribute,id)
        elsif type == :attribute
          ret_val = Hash.new
          unravel_raw_post_hash_ret_val!(ret_val,:ret,child_hash)
          ret << {:id => id, :component_component_id  => parent_id,:value_asserted => ret_val[:ret]}
        else
          raise Error.new("Unexpected type #{type}")
        end
      end
    end

    def self.unravel_raw_post_hash_ret_val!(ret_val,key,obj)
      if obj.kind_of?(Hash)
        obj.each do |k,v|
          num_index = (k =~ NumericIndexRegexp; $1 ? $1.to_i : nil)
          if num_index
            ret_val[key] ||= ArrayObject.new 
            #make sure that  ret_val[key] has enough rows
            while ret_val[key].size <= num_index
              ret_val[key] << Hash.new
            end
            unravel_raw_post_hash_ret_val!(ret_val[key],num_index,v)
          else
            ret_val[key] ||= Hash.new
            unravel_raw_post_hash_ret_val!(ret_val[key],k,v)
          end
        end
      else
        ret_val[key] = (obj.empty? ? nil : obj)
      end
    end

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
        flatten_attribute_when_array!(ret,value_obj,attr,pattern)
      elsif value_obj.kind_of?(Hash)
        flatten_attribute_when_hash!(ret,value_obj,attr,pattern)
      else
        flatten_attribute_when_mismatch!(ret,value_obj,attr,pattern)
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

    def self.flatten_attribute_when_array!(ret,value_obj,attr,pattern)
      array_pat = pattern[:array]
      return flatten_attribute_when_mismatch!(ret,value_obj,attr,pattern) unless array_pat

      if value_obj.empty? 
        ret << attr.merge(:attribute_value => value_obj)
        return nil
      end

      value_obj.each_with_index do |child_val_obj,i|
        child_attr = 
          if attr[:item_path]
            attr.merge(:display_name => "#{attr[:display_name]}#{delim(i)}", :item_path => attr[:item_path] + [i])
          else
            attr.merge(:root_display_name => attr[:display_name], :display_name => "#{attr[:display_name]}#{delim(i)}", :item_path => [i])
        end
        flatten_attribute!(ret,child_val_obj,child_attr,array_pat)
      end
      nil
    end

    #TODO: shoudl we iterate over missiing keys pattern.keys - val_obj.keys)
    def self.flatten_attribute_when_hash!(ret,value_obj,attr,pattern)
      return flatten_attribute_when_mismatch!(ret,value_obj,attr,pattern) if pattern[:array]
      value_obj.each do |k,child_val_obj|
        child_attr = 
          if attr[:item_path]
            attr.merge(:display_name => "#{attr[:display_name]}#{delim(k)}", :item_path => attr[:item_path] + [k.to_sym])
          else
            attr.merge(:root_display_name => attr[:display_name], :display_name => "#{attr[:display_name]}#{delim(k)}", :item_path => [k.to_sym])
        end
        child_pattern = pattern[k.to_s]
        flatten_attribute!(ret,child_val_obj,child_attr,child_pattern)
      end
      nil
    end

    def self.flatten_attribute_when_mismatch!(ret,value_obj,attr,pattern)
      Log.error("mismatch between object #{value_obj.inspect} and pattern #{pattern}")
      ret << (top_level ? attr : attr.merge(:attribute_value => value_obj))
      nil
    end

    def self.delim(x)
      "[#{x.to_s}]"
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
          ret[index] = SchemaPattern.new({:type => "json"})
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
  
  #TODO: this related to syntactic type processing above, but may go in its own file like: attribute_semantic_type
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
