module DTK
  class NodeBindings < Model
    r8_nested_require('node_bindings','content')
    r8_nested_require('node_bindings','parse_input')
    r8_nested_require('node_bindings','dsl')
    r8_nested_require('node_bindings','node_target')

    def self.set_node_bindings(target,assembly,hash_content)
      create_from_hash(assembly,hash_content).set_node_bindings(target,assembly)
    end
    def set_node_bindings(target,assembly)
      pp [:set_node_bindings, self]
    end

    def self.get_node_bindings(assembly_template_idh)
      sp_hash = {
        :cols => [:id,:content],
        :filter => [:eq,:component_component_id,assembly_template_idh.get_id()]
      }
      nb_mh = assembly_template_idh.createMH(:node_bindings)
      get_obj(nb_mh,sp_hash)
    end

    def has_node_target?(assembly_node_name)
      content().has_node_target?(assembly_node_name)
    end

    def self.create_linked_target_ref?(target,node,node_target)
      assembly_instance,node_instance = node_target && node_target.find_matching_instance_info(target,node)
      if node_instance
        Node::TargetRef::Input::BaseNodes.create_linked_target_ref?(target,node_instance,assembly_instance)
      end
    end

   private
    def content()
      if self[:content].kind_of?(Content)
        self[:content]
      elsif content_hash = get_field?(:content)
        self[:content] = Content.parse_and_reify(ParseInput.new(content_hash,:content_field=>true))
      end
    end

    #since only one per assembly can use constant
    def self.node_bindings_ref(content)
      NodeBindingRef
    end
    NodeBindingRef = 'node_bindings_ref'

  end
end
