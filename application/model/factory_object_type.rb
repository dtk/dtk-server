module DTK
  module FactoryObject
    CommonCols = COMMON_REL_COLUMNS.keys - [:local_id,:c,:created_at,:updated_at]
  end
  module FactoryObjectMixin
    def qualified_ref(obj_hash)
      "#{obj_hash[:ref]}#{obj_hash[:ref_num] ? "-#{obj_hash[:ref_num].to_s}" : ""}"
    end
  end
  module FactoryObjectClassMixin
    def create(model_handle,hash_values)
      idh = (hash_values[:id] ? model_handle.createIDH(:id => hash_values[:id]) : model_handle.create_stubIDH())
      self.new(hash_values,model_handle[:c],model_name(),idh)
    end
  end
end
