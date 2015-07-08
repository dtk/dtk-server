module DTK
  class NodeBindings < Model
    r8_nested_require('node_bindings','content')
    r8_nested_require('node_bindings','parse_input')
    r8_nested_require('node_bindings','dsl')
    r8_nested_require('node_bindings','node_target')
    r8_nested_require('node_bindings','target_specific_info')

    def self.set_node_bindings(target,assembly,hash_content)
      create_from_hash(assembly,hash_content).set_node_bindings(target,assembly)
    end

    def set_node_bindings(target,assembly)
      # TODO: here or earlier check that bindings in this mention only logical nodes in the assembly
      content().find_target_specific_info(target).each_pair do |node,target_specific_info|
        if image_val = target_specific_info.node_target_image?()
          assembly.set_attribute(assembly_node_attribute(:image,node),image_val, create: true)
        end
        if size_val = target_specific_info.size()
          assembly.set_attribute(assembly_node_attribute(:size,node),size_val, create: true)
        end
      end
    end

    def assembly_node_attribute(type,node)
      "#{node}/#{MappingToAssemblyAttr[type]}"
    end
    private :assembly_node_attribute
    MappingToAssemblyAttr = {
      image: :os_identifier,
      size: :memory_size
    }

    def self.get_node_bindings(assembly_template_idh)
      sp_hash = {
        cols: [:id,:content],
        filter: [:eq,:component_component_id,assembly_template_idh.get_id()]
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

    def content
      if self[:content].is_a?(Content)
        self[:content]
      elsif content_hash = get_field?(:content)
        self[:content] = Content.parse_and_reify(ParseInput.new(content_hash,content_field: true))
      end
    end

    #since only one per assembly can use constant
    def self.node_bindings_ref(_content)
      NodeBindingRef
    end
    NodeBindingRef = 'node_bindings_ref'
  end
end
