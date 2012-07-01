module DTK
  module ContentObjectClassMixin
    def create(model_handle,hash_values)
      idh = (hash_values[:id] ? model_handle.createIDH(:id => hash_values[:id]) : model_handle.create_stubIDH())
      self.new(hash_values,model_handle[:c],model_name(),idh)
    end
  end
end
