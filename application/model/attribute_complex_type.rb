#TODO: just stubbing now with cached hashes
module XYZ
  class AttributeComplexType < Model
    set_relation_name(:attribute,:complex_type)
    def self.up()
    end
    #helper fns
    def self.has_required_fields_given_semantic_type?(obj,semantic_type)
      pattern =  SemanticTypeSchema.create_from_semantic_type(semantic_type)
      return nil unless pattern
      has_required_fields?(obj,pattern)
    end

    def self.flatten_attribute_list(attr_list,opts={})
      ret = Array.new
      attr_list.each do |attr|
        value = attr[:attribute_value]
        if (value.nil? and not opts[:flatten_nil_value]) or not attr[:data_type] == "json"
          ret << attr 
        else
          nested_type_pat = SemanticTypeSchema.create_from_semantic_type(attr[:semantic_type])
          if nested_type_pat
            flatten_attribute!(ret,value,attr,nested_type_pat,opts.merge(:top_level=> true))
          else 
            ret << attr
          end
        end
      end
      ret
    end

    def self.ravel_raw_post_hash(raw_post_hash,type,parent_id=nil)
      raise Error.new("Unexpected type #{type}") unless type == :attribute  #TODO: may teat other types like component
      indexed_ret = Hash.new
      ravel_raw_post_hash_attribute!(indexed_ret,raw_post_hash,parent_id)
      indexed_ret.values
    end

    def self.serialze(token_array)
      token_array.join(Delim::Common)
    end

   private

    TypeMapping = {
      :attribute => :a,
      :component => :c
    }

    def self.item_path_token_array(attr)
      return nil unless attr[:item_path]
      attr[:item_path].map{|indx| indx.kind_of?(Numeric) ? "#{Delim::NumericIndex}#{indx.to_s}" : indx.to_s} 
    end
    def self.container_id(type,id)
      return nil if id.nil?
      "#{TypeMapping[type.to_sym]}#{Delim::Common}#{id.to_s}"
    end

    def self.ravel_raw_post_hash_attribute!(ret,attributes_hash,parent_id=nil)
      attributes_hash.each do |k,attr_hash|
        id,path = (k =~ AttrIdRegexp) && [$1.to_i,$2]
        next unless id
        ret[id] ||= {:id => id,DB.parent_field(:component,:attribute) => parent_id}
        if path.empty? 
          ret[id][:value_asserted] = attr_hash
        else
          ravel_raw_post_hash_attribute_aux!(ret[id],:value_asserted,attr_hash,path)
        end
      end
    end
    AttrIdRegexp = Regexp.new("^#{TypeMapping[:attribute]}#{Delim::Common}([0-9]+)(.*$)")

    def self.ravel_raw_post_hash_attribute_aux!(ret,index,hash,path)
      next_index, rest_path = (path =~ NumericIndexRegexp) && [$1.to_i,$2]
      if path =~ NumericIndexRegexp
        next_index, rest_path = [$1.to_i,$2]
        ret[index] ||= ArrayObject.new 
        #make sure that  ret[index] has enough rows
        while ret[index].size <= next_index
          ret[index] << nil
        end
      elsif path =~ KeyWithRestRegexp
        next_index, rest_path = [$1,$2]
        ret[index] ||= Hash.new
      elsif path =~ KeyWORestRegexp
        next_index, rest_path = [$1,String.new]
        ret[index] ||= Hash.new
      else
        Log.error("parsing error on path #{path}")
      end

      if rest_path.empty?
        ret[index][next_index] = hash
      else
        ravel_raw_post_hash_attribute_aux!(ret[index],next_index,hash,rest_path)
      end
    end
    NumericIndexRegexp = Regexp.new("^#{Delim::Common}#{Delim::NumericIndex}([0-9]+)(.*$)")
    KeyWithRestRegexp = Regexp.new("^#{Delim::Common}([^#{Delim::Char}]+)#{Delim::Common}(.+$)")
    KeyWORestRegexp = Regexp.new("^#{Delim::Common}(.*$)")

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
    def self.flatten_attribute!(ret,value_obj,attr,pattern,opts={})
      if pattern.nil?
        flatten_attribute_when_nil_pattern!(ret,value_obj,attr,opts)
      elsif pattern.is_atomic?()
        flatten_attribute_when_atomic_pattern!(ret,value_obj,attr,pattern,opts)
      elsif value_obj.kind_of?(Array) or (pattern.is_array?() and value_obj.nil? and opts[:flatten_nil_value]) 
        flatten_attribute_when_array!(ret,value_obj,attr,pattern,opts)
      elsif value_obj.kind_of?(Hash) or (pattern.is_hash?() and value_obj.nil? and opts[:flatten_nil_value])
        flatten_attribute_when_hash!(ret,value_obj,attr,pattern,opts.merge(:top_level=>false))
      else
        flatten_attribute_when_mismatch!(ret,value_obj,attr,pattern,opts.merge(:top_level=>false))
      end
      nil
    end

    def self.flatten_attribute_when_nil_pattern!(ret,value_obj,attr,opts={})
      if attr[:data_type] == "json" and opts[:top_level]
        ret << attr
      else
        ret << attr.merge(:attribute_value => value_obj,:data_type => "json")
      end    
      nil
    end

    def self.flatten_attribute_when_atomic_pattern!(ret,value_obj,attr,pattern,opts={})
      if attr[:data_type] == pattern[:type].to_s and opts[:top_level]
        ret << attr
      else
        ret << attr.merge(:attribute_value => value_obj,:data_type => pattern[:type].to_s)
      end    
      nil
    end

    def self.flatten_attribute_when_array!(ret,value_obj,attr,pattern,opts={})
      array_pat = pattern[:array]
      return flatten_attribute_when_mismatch!(ret,value_obj,attr,pattern,opts) unless array_pat

      if (value_obj||[]).empty? and not opts[:flatten_nil_value] 
        ret << attr.merge(:attribute_value => value_obj)
        return nil
      end

      #if nil value_obj then just assume one row
      child_list = (value_obj||[]).empty? ? [nil] : value_obj
      child_list.each_with_index do |child_val_obj,i|
        child_attr = 
          if attr[:item_path]
            attr.merge(:display_name => "#{attr[:display_name]}#{display_name_num_delim(i)}", :item_path => attr[:item_path] + [i])
          else
            attr.merge(:root_display_name => attr[:display_name], :display_name => "#{attr[:display_name]}#{display_name_num_delim(i)}", :item_path => [i])
        end
        flatten_attribute!(ret,child_val_obj,child_attr,array_pat,opts)
      end
      nil
    end

    #TODO: shoudl we iterate over missiing keys pattern.keys - val_obj.keys)
    def self.flatten_attribute_when_hash!(ret,value_obj,attr,pattern,opts={})
      return flatten_attribute_when_mismatch!(ret,value_obj,attr,pattern,opts) if pattern[:array] or ((value_obj||{}).empty? and not opts[:flatten_nil_value])
      child_list = (value_obj||{}).empty? ? pattern.inject({}){|h,kv|h.merge(kv[0].to_sym => nil)} : value_obj 
      child_list.each do |k,child_val_obj|
        child_attr = 
          if attr[:item_path]
            attr.merge(:display_name => "#{attr[:display_name]}#{display_name_delim(k)}", :item_path => attr[:item_path] + [k.to_sym])
          else
            attr.merge(:root_display_name => attr[:display_name], :display_name => "#{attr[:display_name]}#{display_name_delim(k)}", :item_path => [k.to_sym])
        end
        child_pattern = pattern[k.to_s]
        flatten_attribute!(ret,child_val_obj,child_attr,child_pattern,opts)
      end
      nil
    end

    def self.flatten_attribute_when_mismatch!(ret,value_obj,attr,pattern,opts={})
      Log.error("mismatch between object #{value_obj.inspect} and pattern #{pattern.inspect}")
      ret << (opts[:top_level] ? attr : attr.merge(:attribute_value => value_obj))
      nil
    end

    def self.display_name_delim(x)
      Delim::DisplayName+(x.to_s)
    end
    def self.display_name_num_delim(x)
      Delim::DisplayName+Delim::NumericIndex+(x.to_s)
    end
  end
end
