module XYZ
  class NodeBindingRuleset < Model
    def self.common_columns()
      [:id,:display_name,:type,:os_type,:rules]
    end
    
    def clone_or_match(target)
      update_object!(:type,:rules)
      case self[:type]
       when "clone"
        clone(target)
       when "match"
        match(target)
      else
        raise Error.new("Unexpected type (#{self[:type]}) in node bidning ruleset")
      end
    end
   private
    def match(target)
      raise Error.new("TODO: not implemented yet")
    end
    
    def clone(target)
      #match conditions in ruleset with properties on target
      unless match = clone_match(,target)
        raise Error.new("No rules in teh node being match the target")
      end
      node_template = match[:node_template]
    end
    def clone_match(target)
      rules = self[:rules]
      #TODO: stub
      rules.first
      #TODO: add any target defaults like security groups
    end
  end
end

