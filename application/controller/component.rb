module XYZ
  class ComponentController < MainController
    def self.field_set()
      [
        :id,
        :display_name,
        :description,
        :parent_id,
        :parent_path
      ]   
    end
  end
end
