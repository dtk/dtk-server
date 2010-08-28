module XYZ
  class ComponentController < Controller
#TODO: move field set out of here and into meta/component/component.defs.rb file
    def self.field_set()
      [
        :id,
        :display_name,
        :type,
        :external_cmp_ref,
        :description,
        :parent_id,
        :parent_path
      ]   
    end

  end
end
