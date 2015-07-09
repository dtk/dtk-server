module DTK; class NodeGroup
  module Clone; module Mixin
    def clone_post_copy_hook(clone_copy_output, opts = {})
      return if opts[:no_post_copy_hook]
      super_opts = opts.merge(donot_create_pending_changes: true, donot_create_internal_links: true)
      super(clone_copy_output, super_opts)
      opts[:outermost_ports] = super_opts[:outermost_ports] if super_opts[:outermost_ports]

      clone_source_obj = clone_copy_output.source_object
      component = clone_copy_output.objects.first
      override_attrs = { ng_component_id: component[:id] }
      node_clone_opts = [:ret_new_obj_with_cols].inject({}) do |h, k|
        opts.key?(k) ? h.merge(k => opts[k]) : h
      end
      get_node_group_members().each { |node| node.clone_into(clone_source_obj, override_attrs, node_clone_opts) }
    end

    # clone components and links on this node group to node
    def clone_into_node(node)
      # get the components on the node group (except those created through link def on create event since these wil be created in clone_external_attribute_links call
      ng_cmps = get_objs(cols: [:cmps_for_clone_into_node]).map { |r| r[:component] }
      return if ng_cmps.empty?
      node_external_ports = clone_components(ng_cmps, node)
      clone_external_attribute_links(node_external_ports, node)
    end

                  private

    def clone_components(node_group_cmps, node)
      external_ports = []
      # order components to respect dependencies
      ComponentOrder.derived_order(node_group_cmps) do |ng_cmp|
        clone_opts = {
          ret_new_obj_with_cols: [:id, :display_name],
          outermost_ports: [],
          use_source_impl_and_template: true,
          no_constraint_checking: true
        }
        override_attrs = { ng_component_id: ng_cmp[:id] }
        node.clone_into(ng_cmp, override_attrs, clone_opts)
        external_ports += clone_opts[:outermost_ports]
      end
      external_ports
    end

    def clone_external_attribute_links(node_external_ports, node)
      port_link_info = ret_port_link_info(node_external_ports)
      return if port_link_info.empty?
      # TODO: can also look at approach were if one node member exists already can do simpler copy
      port_link_info.each do |pl|
        port_link = pl[:node_group_port_link]
        port_link.create_attribute_links(node.id_handle)
      end
    end

    def ret_port_link_info(node_external_ports)
      ret = []
      return ret if node_external_ports.empty?
      # TODO: this makes asseumption that can find cooresponding port on node group by matching on port display_name
      # get the node group ports that correspond to node_external_ports
      # TODO: this can be more efficient if made into ajoin
      ng_id = id()
      raise Error.new('Need to check: semantics of :link_def_info has changed to use outer joins')
      sp_hash = {
        cols: [:id, :link_def_info, :display_name],
        filter: [:and, [:eq, :node_node_id, ng_id], [:oneof, :display_name, node_external_ports.map { |r| r[:display_name] }]]
      }
      ng_ports = Model.get_objs(model_handle(:port), sp_hash)
      ng_port_ids = ng_ports.map { |r| r[:id] }

      # get the ng_port links
      sp_hash = {
        cols: [:id, :group_id, :input_id, :output_id, :temporal_order],
        filter: [:or, [:oneof, :input_id, ng_port_ids], [:oneof, :output_id, ng_port_ids]]
      }
      ng_port_links = Model.get_objs(model_handle(:port_link), sp_hash)

      # form the node_port_link_hashes by subsitituting corresponding node port sfor ng ports
      ndx_node_port_ids = node_external_ports.inject({}) { |h, r| h.merge(r[:display_name] => r[:id]) }
      ndx_ng_ports = ng_ports.inject({}) { |h, r| h.merge(r[:id] => r) }
      ng_port_links.map do |ng_pl|
        if ng_port_ids.include?(ng_pl[:input_id])
          index = :input_id
          ng_port_id = ng_pl[:input_id]
        else
          index = :output_id
          ng_port_id = ng_pl[:output_id]
        end
        port_display_name = ndx_ng_ports[ng_port_id][:display_name]
        node_port_id = ndx_node_port_ids[port_display_name]
        other_index = (index == :input_id ? :output_id : :input_id)
        { node_group_port_link: ng_pl, node_port_link_hash: { index => node_port_id, other_index => ng_pl[other_index] } }
      end
    end
  end; end
end; end

=begin
TODO: ***; may want to put in version of this for varaibles taht are not input ports; so change to var at node group level propagates to teh node members; for matching would not leverage the component ng_component_id

TODO: currently not used because instead treating node group more like proxy for node members; keeping in
for now in case turns out taking this approach will be more efficient
      node_components = get_node_group_members().map{|node|node.clone_into(clone_source_obj,override_attrs,node_clone_opts)}

      unless node_components.empty?
        ng_component = clone_copy_output.objects.first
        add_links_between_ng_and_node_components(ng_component,node_components)
      end

    end
   private

# this is use technique that links between ng and component attributes and indirect propagation; problematic when the node groupo side has output attribute
alternative is adding links at time that node to ng link is added and special processing when attribute changed at ng level
     def add_links_between_ng_and_node_components(ng_cmp,node_cmps)
       # get all the relevant attributes
       ng_cmp_id = ng_cmp[:id]
       ng_plus_node_cmp_ids = node_cmps.map{|r|r[:id]} + [ng_cmp_id]
       attr_mh = ng_cmp.model_handle(:attribute)

       cols = AttributeLink.attribute_info_cols()
       cols << AttrFieldToMatchOn unless cols.include?(AttrFieldToMatchOn)
       cols << :component_component_id unless cols.include?(:component_component_id)
       sp_hash = {
         :cols => cols,
         :filter => [:oneof, :component_component_id, ng_plus_node_cmp_ids]
       }
       attrs = Model.get_objs(attr_mh,sp_hash)
       return if attrs.empty?

       # partition into attributes on node group and ones on nodes
       # index by AttrFieldToMatchOn
       ng_ndx = attrs.select{|r|r[:component_component_id] == ng_cmp_id}.inject({}) do |h,r|
         h.merge(r[AttrFieldToMatchOn] => r[:id])
       end
       # build up link rows to create
       attr_link_rows = attrs.select{|r|r[:component_component_id] != ng_cmp_id}.map do |r|
         index = r[AttrFieldToMatchOn]
         {
           :output_id => ng_ndx[index],
           :input_id => r[:id],
           :function => "eq"
         }
       end
       opts = {:donot_create_pending_changes => true, :attr_rows => attrs}
       parent_idh =  id_handle().get_top_container_id_handle(:target,:auth_info_from_self => true)
       AttributeLink.create_attribute_links(parent_idh,attr_link_rows,opts)
     end

     AttrFieldToMatchOn = :display_name
=end
