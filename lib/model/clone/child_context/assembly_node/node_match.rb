module DTK; class Clone::ChildContext::AssemblyNode
  class NodeMatch
    attr_reader :node, :mapping, :external_ref
    def initialize(node, mapping, external_ref = nil)
      @node         = node
      @mapping      = mapping
      @external_ref = external_ref
    end

    private :initialize

    def self.hash__when_creating_node(parent, node, node_template, opts={})
      instance_type = node.is_assembly_wide_node?() ? node_class(node).assembly_wide : node_class(node).staged
      ret = {
        instance_type: instance_type,
        node_stub_idh: node.id_handle,
        instance_display_name: node[:display_name],
        instance_ref: instance_ref(parent, node[:display_name]),
        node_template_idh: node_template.id_handle()
      }
      if node_target = opts[:node_target]
        if external_ref = node_target.external_ref?
          ret.merge!(external_ref: external_ref)
        end
      end
      ret
    end
    
    def self.hash__when_match(parent, node, target_ref, extra_fields = {})
      ret = {
        instance_type: node_class(node).instance,
        node_stub_idh: node.id_handle,
        instance_display_name: node[:display_name],
        instance_ref: instance_ref(parent, node[:display_name]),
        node_template_idh: target_ref.id_handle(),
        donot_clone: [:attribute]
      }
      ret.merge!(extra_fields) unless extra_fields.empty?
      ret
    end

    # Returns the node to template mappings given by NodeTemplateMapping indexed by instance display name
    def self.ndx_node_matches(hash_matches)
      hash_matches.inject({}) do |h, node_match|
        ndx = display_name = node_match[:instance_display_name]
        node_template_id = node_match[:node_template_idh].get_id()
        mapping = {
          type: node_match[:instance_type],
          ancestor_id: node_match[:node_stub_idh].get_id(),
          canonical_template_node_id: node_template_id,
          node_template_id: node_template_id,
          display_name: display_name,
          ref: node_match[:instance_ref]
        }
        external_ref = node_match[:external_ref]
        h.merge(ndx => new(node_match, mapping, external_ref))
      end
    end

    private

    def self.node_class(node)
      node.is_node_group?() ? Node::Type::NodeGroup : Node::Type::Node
    end

    def self.instance_ref(parent, node_ref_part)
      "assembly--#{parent[:assembly_obj_info][:display_name]}--#{node_ref_part}"
    end
  end
end; end              
