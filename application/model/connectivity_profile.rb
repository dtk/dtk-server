module XYZ
  class ConnectivityProfile < ArrayObject
    #TODO: both args not needed if update the type hierarchy with leaf components 
    def self.find(cmp_type_x,most_specific_type_x)
      ret = self.new()
      cmp_type = cmp_type_x && cmp_type_x.to_sym
      most_specific_type = most_specific_type_x && most_specific_type_x.to_sym
      rules = get_possible_component_connections()
      ret_array = rules.map do |rule_input_cmp_type,rest|
        component_type_match(cmp_type,most_specific_type,rule_input_cmp_type) ? rest.merge(:input_component_type => rule_input_cmp_type) : nil
      end.compact
      self.new(ret_array)
    end

    def match_output(cmp_type_x,most_specific_type_x)
      ret = nil
      cmp_type = cmp_type_x && cmp_type_x.to_sym
      most_specific_type = most_specific_type_x && most_specific_type_x.to_sym
      self.each do |one_match|
        (one_match[:output_components]||[]).each do |output_info|
          rule_output_cmp_type = output_info.keys.first
          next unless self.class.component_type_match(cmp_type,most_specific_type,rule_output_cmp_type)
          #TODO: not looking for multiple matches and just looking fro first one
          ret = Aux::hash_subset(one_match,[:input_component_type,:required,:connection_type]).merge(:output_component_type => rule_output_cmp_type)
          info = output_info.values.first
          ams = info[:attribute_mappings]
          ret.merge!(ams ? info.merge(:attribute_mappings => ams.map{|x|AttributeMapping.new(x)}) : info)
          break
        end
        break if ret
      end
      ret
    end

   private
    def self.component_type_match(cmp_type,most_specific_type,rule_cmp_type)
      return true if (cmp_type == rule_cmp_type or most_specific_type == rule_cmp_type)
      type_class = ComponentType.ret_class(rule_cmp_type)
      type_class and type_class.include?(cmp_type)
    end
    def self.get_possible_component_connections()
      @possible_connections ||= XYZ::PossibleComponentConnections #TODO: stub
    end
  end

  class AttributeMapping < HashObject
    def get_attribute(dir,input_component,output_component)
      component,path = get_component_and_path(dir,input_component,output_component)
      #TODO: hard coded for certain cases; generalize to follow path which would be done by dynmaically generating join
      if path.size == 1 and not is_special_key?(path.first)
        component.get_virtual_attribute(path.first.to_s,[:id],:display_name)
      elsif path.size == 3 and is_special_key_type?(:parent,path.first)
        node = component.id_handle.createIDH(:model_name => :node, :id => component[:node_node_id]).create_object()
        node.get_virtual_component_attribute(path[1].to_s,path[2].to_s,[:id],:display_name)
      else
        raise Error.new("Not implemented yet")
      end
    end

   private
    #returns [component,path]; dups path so it can be safely modified
    def get_component_and_path(dir,input_component,output_component)
      component = nil
      path = nil
      if is_special_key_type?([:input_component,:output_component],self[dir])
        type_to_find = (dir == :input) ? :input_component : :output_component
        dir_to_use =
          if is_special_key_type?(type_to_find,self[:input]) then :input
          elsif is_special_key_type?(type_to_find,self[:output]) then :output
          end
        raise Error.new("unexepected argumenets") unless dir_to_use
        component = (dir_to_use == :input) ? input_component : output_component
        path = self[:dir_to_use].dup
        path.shift
      else
        component = (dir == :input) ? input_component : output_component
        path = self[dir].dup
      end
      [component,path]
    end

    def is_special_key?(item)
      (item.kind_of?(String) or item.kind_of?(Symbol)) and item.to_s =~ /^__/
    end
    def is_special_key_type?(type_or_types,item)
      types = Array[type_or_types]
      item.respond_to?(:to_sym) and types.map{|t|"__#{t}"}.include?(item.to_s)
    end
  end
end
