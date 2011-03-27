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
          ret = Aux::hash_subset(one_match,[:input_component_type,:required,:connection_type]).merge(:output_component_type => rule_output_cmp_type).merge(output_info.values.first)
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
#TODO: remove    x=find_matching_rule(:mysql_db_server,:mysql_db_server)
  
  end
end
