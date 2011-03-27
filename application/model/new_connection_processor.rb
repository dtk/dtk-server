module XYZ
  class NewConnectionProcessor
    def self.find_component_connectivity_profile(input_cmp_type_x)
      ret = Array.new
      return ret if input_cmp_type_x.nil?
      input_cmp_type = input_cmp_type_x.to_sym
      rules = get_possible_component_connections()
      rules.map do |rule_input_cmp_type,rest|
        component_type_match(input_cmp_type,rule_input_cmp_type) ? rest.merge(:input_component_type => rule_input_cmp_type) : nil
      end.compact
    end

   private
    #TODO:rewrite in terms of find_component_connectivity_profile
    #Dont forget to convert to sym
    def self.find_matching_rule(input_cmp_type,output_cmp_type)
      ret = nil
      rules = get_possible_component_connections()
      rules.each do |rule_input_cmp_type,rest|
        next unless component_type_match(input_cmp_type,rule_input_cmp_type)
        (rest[:output_components]||[]).each do |output_info|
          rule_output_cmp_type = output_info.keys.first
          next unless component_type_match(output_cmp_type,rule_output_cmp_type)
          #TODO: not looking for multiple matches and just looking fro first one
          ret = {
            :input_component_type => rule_input_cmp_type,
            :output_component_type => rule_output_cmp_type
          }.merge(output_info.values.first)
          break
        end
      end
      ret
    end
   
    def self.component_type_match(cmp_type,rule_cmp_type)
      return true if cmp_type == rule_cmp_type
      type_class = ComponentType.ret_class(rule_cmp_type)
      type_class and type_class.include?(cmp_type)
    end
    def self.get_possible_component_connections()
      @possible_connections ||= XYZ::PossibleComponentConnections #TODO: stub
    end
#TODO: remove    x=find_matching_rule(:mysql_db_server,:mysql_db_server)
  
  end
end
