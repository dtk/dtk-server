module XYZ
  class AttributeConstraint < Model
    set_relation_name(:attribute,:constraint)
    def self.up()
      foreign_key :attribute_id, :node, FK_CASCADE_OPT
      foreign_key :constraint_id, :search_object, FK_CASCADE_OPT
    end
  end
end


