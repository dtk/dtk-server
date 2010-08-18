module XYZ
  class ComponentController < MainController
    def self.field_set()
      [
        :id,
        :display_name,
        :external_cmp_ref,
        :description,
        :parent_id,
        :parent_path
      ]   
    end
  end
end
