module DTK
  class NodeImage < Model
    def self.map_local_term(target,logical_image_name)
      legacy_bridge_get_object_from_old_form(target,logical_image_name)
    end
   private
    def self.legacy_bridge_get_object_from_old_form(target,logical_image_name)
      Node::Template.find_image_id_and_os_type(logical_image_name,target)
    end
  end
end
