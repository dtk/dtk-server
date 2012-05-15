module XYZ
  class NodeBindingRuleset < Model
    def self.common_columns()
      [:id,:display_name,:type,:os_type,:rules]
    end
  end
end

