module DTK
  class NodeImage < Model
    def self.find_iaas_match(target,logical_image_name)
      legacy_bridge_to_node_template(target,logical_image_name)
    end

    private

    def self.legacy_bridge_to_node_template(target,logical_image_name)
      image_id, os_type = Node::Template.find_image_id_and_os_type(logical_image_name,target)
      image_id
    end
  end
end
