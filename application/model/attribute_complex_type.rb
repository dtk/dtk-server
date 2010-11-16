#TODO: just stubbing now with cached hashes
module XYZ
  class AttributeComplexType < Model
    set_relation_name(:attribute,:complex_type)
    def self.up()
    end
    #helper fns
    def self.has_required_fields_given_semantic_type?(obj,semantic_type)
      required_pat =  Required[semantic_type]
      return nil unless required_pat
      has_required_fields?(obj,required_pat)
    end

    def self.flatten_attribute_list(attr_list)
      ret = Array.new
      attr_list.each do |attr|
        value = attr[:attribute_value]
        if value.nil? or not attr[:data_type] == "json"
          ret << attr 
        else
          nested_type_pat = ret_schema_from_attribute(attr)
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
    def self.ret_schema_from_attribute(attr)
      semantic_type = attr[:semantic_type]
      return nil unless semantic_type
      key = semantic_type_key(semantic_type)
      return NestedTypes[key] if NestedTypes[key]
      return ret_schema_from_semantic_type(semantic_type) if semantic_type.kind_of?(Hash)

      Log.error("found semantic type #{semantic_type.inspect} that does not have a nested type definition")
      nil
    end

    def self.semantic_type_key(semantic_type)
      ret = (semantic_type.kind_of?(Hash) ? semantic_type.keys.first : semantic_type).to_s
      ret == ":array" ? :array : ret
    end

    def self.ret_schema_from_semantic_type(semantic_type)
      ret = HashObject.create_with_auto_vivification()
      ret_schema_from_semantic_type_aux!(ret,semantic_type_key(semantic_type),semantic_type.values.first)
      return ret.empty? ? nil : ret.freeze
    end

    def self.ret_schema_from_semantic_type_aux!(ret,index,semantic_type)
      key = semantic_type_key(semantic_type)
      if NestedTypes[key]
        ret[index] = NestedTypes[key]
      elsif semantic_type.kind_of?(Hash)
        ret_schema_from_semantic_type_aux!(ret[index],key,semantic_type.values.first)        
      else
        ret[index] = "json"
      end
    end

    #TODO: stub
    #TODO: should unify Required and data type and view also data types as optional or possibly incomplete to allow gamut from compleetly
    #specified to un specfied
    Required = 
      {
      "sap_config" => {
        :array => {
          "type" =>  true,
          "port" => true,
          "protocol" => true
        }
      },
      "sap" => {
        :array => {
          "type" =>  true,
          "port" => true,
          "protocol" => true,
          "host" => true,
        }
      },
      "db_info" => {
        :array => {
          "username" =>  true,
          "database" => true,
          "password" => true
        }
      }
    }
    NestedTypes =
      {
      "sap_config[ipv4]" => {
        "port" => :integer,
        "protocol" => :string,
        "binding_addr_constraints" => :json
      },
      "sap[ipv4]" => {
        "port" => :integer,
        "protocol" => :string,
        "host_address" => :string
      },
      "sap_ref" => {
        "port" => :integer,
        "protocol" => :string,
        "host_address" => :string,
        "socket_file" => :string
      },

      "sap[socket]" => {
        "socket_file" => :string
      },

      "db_info" => {
        "username" =>  :string,
        "database" => :string,
        "password" => :string
      }
    }

    def self.has_required_fields?(value_obj,pattern)
      #care must be taken to make thsi three-valued
      if value_obj.kind_of?(Array)
        array_pat = pattern[:array]
        if array_pat
          return false if value_obj.empty? 
          value_obj.each do |el|
            ret = has_required_fields?(el,array_pat)
            return ret unless ret.kind_of?(TrueClass)
          end
          return true
        end
        Log.error("mismatch between object #{value_obj.inspect} and pattern #{pattern}")
      elsif value_obj.kind_of?(Hash)
        if pattern[:array]
          Log.error("mismatch between object #{value_obj.inspect} and pattern #{pattern}")
          return nil
        end
        pattern.each do |k,child_pat|
          el = value_obj[k.to_sym]
          return false unless el
          next if child_pat.kind_of?(TrueClass)
          ret = has_required_fields?(el,child_pat)
          return ret unless ret.kind_of?(TrueClass) 
        end
        return true
      else
        Log.error("mismatch between object #{value_obj.inspect} and pattern #{pattern}")
      end
      nil
    end
    #TODO: fix up so pattern can be omitted or partial; if omitted then just follow hash structure; can also have json data type means stop 
    #flattening
    #TODO: add "index that will be used to tie unravvled attribute back to the base object and make sure
    #base object in the attribute
    #TODO: also if value is null but pattern, then follow the pattern to flesh out with nulls
    def self.flatten_attribute!(ret,value_obj,attr,pattern,top_level=false)
      if not pattern.kind_of?(Hash)
        flatten_attribute_when_scalar!(ret,value_obj,attr,pattern,top_level)
      elsif value_obj.kind_of?(Array)
        flatten_attribute_when_array!(ret,value_obj,attr,pattern,top_level)
      elsif value_obj.kind_of?(Hash)
        flatten_attribute_when_hash!(ret,value_obj,attr,pattern,top_level)
      else
        flatten_attribute_when_mismatch!(ret,value_obj,attr,pattern,top_level)
      end
      nil
    end

    def self.flatten_attribute_when_scalar!(ret,value_obj,attr,pattern,top_level)
      if attr[:data_type] == pattern.to_s and top_level
        ret << attr
      else
        ret << attr.merge(:attribute_value => value_obj,:data_type => pattern.to_s)
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
   
    def self.flatten_attribute_when_hash!(ret,value_obj,attr,pattern,top_level)
      return flatten_attribute_when_mismatch!(ret,value_obj,attr,pattern,top_level) if pattern[:array]
      #TODO: change so if difference in keys, you add union (providing nulls when pattern has column but ob doesnt)
      #only if keys in pattern completely line up with keys in val object  
      val_keys = value_obj.keys
      pat_keys = pattern.keys
      unless val_keys.size == pat_keys.size and val_keys.map{|x|x.to_s}.sort == pat_keys.sort 
        return flatten_attribute_when_mismatch!(ret,value_obj,attr,pattern,top_level)
      end
      
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
  end
end
