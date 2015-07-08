module DTK
  module FactoryObject
    CommonCols = COMMON_REL_COLUMNS.keys - [:local_id,:c,:created_at,:updated_at]
  end
  module FactoryObjectCommon
    def assembly_template_node_ref(assembly_ref,node_ref)
      "#{assembly_ref}--#{node_ref}"
    end
  end

  module FactoryObjectMixin
    include FactoryObjectCommon
    def qualified_ref(obj_hash)
      "#{obj_hash[:ref]}#{obj_hash[:ref_num] ? "-#{obj_hash[:ref_num]}" : ""}"
    end

    def id_handle_if_object_exists?
      ret = id_handle()
      ret if ret.get_id()
    end
  end
  module FactoryObjectClassMixin
    include FactoryObjectCommon

    def create(model_handle,hash_values)
      idh = (hash_values[:id] ? model_handle.createIDH(id: hash_values[:id]) : model_handle.create_stubIDH())
      new(hash_values,model_handle[:c],model_name(),idh)
    end

    def subclass_model(model_object)
      new(model_object,model_object.model_handle[:c],model_name(),model_object.id_handle())
    end
  end
end
