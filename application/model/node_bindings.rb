module DTK
  class NodeBindings
    def self.find_matching_existing_node(target,node,assembly_template_idh)
      target.model_handle(:node).createIDH(:id => 2147545873).create_object()
    end
  end
end
