module XYZ
  class NewConnectionProcessor
    #TODO: this should be private after testing
    def self.find_matching_rule(input_cmp,output_cmp)
      ret = nil
      rules = get_possible_component_connections()
      rules.each do |rule_in_cmp,rest|
        
      end
      nil
    end
    private
    def self.get_possible_component_connections()
      @possible_connections ||= XYZ::PossibleComponentConnections #TODO: stub
    end
  end
end
