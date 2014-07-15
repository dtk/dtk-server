module DTK
  class NodeBindings
    r8_nested_require('node_bindings','content')
    r8_nested_require('node_bindings','parse_input')
    r8_nested_require('node_bindings','dsl')
    r8_nested_require('node_bindings','node_target')

    def self.create_linked_target_ref?(target,node,assembly_template_idh)
      if node_bindings = get_node_bindings(assembly_template_idh)
        assembly_instance,node_instance = node_bindings.find_matching_instance_info(target,node)
        if node_instance
          Node::TargetRef::Input::BaseNodes.create_linked_target_ref?(target,node_instance,assembly_instance)
        end
      end
    end

    #returns if match [assembly_instance,node_instance]
    def find_matching_instance_info(target,node)
      if node_target = content().has_node_target?(node)
        node_target.find_matching_instance_info(target,node)
      end
    end

   private
    def content()
      if self[:content].kind_of?(Content)
        self[:content]
      elsif content_hash = get_field?(:content)
        Content.parse_and_reify(ParseInput.new(content_hash))
      end
    end

    def self.get_node_bindings(assembly_template_idh)
      sp_hash = {
        :cols => [:id,:content],
        :filter => [:eq,:component_component_id,assembly_template_idh.get_id()]
      }
      nb_mh = assembly_template_idh.createMH(:node_bindings)
      get_obj(nb_mh,sp_hash)
    end

  end
end
