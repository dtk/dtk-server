module DTK
  class PortLink < Model
    def self.common_columns
      [:id,:group_id,:input_id,:output_id,:assembly_id,:temporal_order]
    end

    def self.check_valid_id(model_handle,id,opts={})
      if opts.empty?()
        check_valid_id_default(model_handle,id)
      elsif Aux.has_just_these_keys?(opts,[:assembly_idh])
        sp_hash = {
          cols: [:id,:group_id,:assembly_id],
          filter: [:eq,:id,id]
        }
        rows = get_objs(model_handle,sp_hash)
        unless port_link = rows.first
          raise ErrorIdInvalid.new(id,pp_object_type())
        end
        unless port_link[:assembly_id] == opts[:assembly_idh].get_id()
          raise ErrorUsage.new("Port with id (#{id}) does not belong to assembly")
        end
        id
      else
        raise Error.new("Unexpected options (#{opts.inspect})")
      end
    end

    # create port link adn associated attribute links
    # can clone if needed attributes on a service node group to its members
    def self.create_port_and_attr_links__clone_if_needed(target_idh,port_link_hash,opts={})
      unless link_def_context = get_link_def_context?(target_idh,port_link_hash)
        raise PortLinkError.new("Illegal link")
      end
      port_link_to_create = port_link_hash.merge(temporal_order: link_def_context.temporal_order)
      port_link = nil
      Transaction do
        port_link = create_from_links_hash(target_idh,[port_link_to_create],opts).first
        AttributeLink.create_from_link_defs__clone_if_needed(target_idh,link_def_context,opts.merge(port_link_idh: port_link.id_handle))
      end
      port_link
    end

    # create attribute links from this port link
    def create_attribute_links(parent_idh,opts={})
      # The reason to have create_attribute_links is to document callers from which we know no cloning will be needed
      create_attribute_links__clone_if_needed(parent_idh,opts)
    end
    # can clone if needed attributes on a service node group to its members
    # this sets temporal order if have option :set_port_link_temporal_order
    def create_attribute_links__clone_if_needed(parent_idh,opts={})
      update_obj!(:input_id,:output_id)
      unless link_def_context = get_link_def_context?(parent_idh)
        raise PortLinkError.new("Illegal link")
      end
      if opts[:set_port_link_temporal_order]
        if temporal_order = link_def_context.temporal_order
          update(temporal_order: temporal_order)
        end
      end
      opts_create = Aux.hash_subset(opts,[:filter]).merge(port_link_idh: id_handle())
      AttributeLink.create_from_link_defs__clone_if_needed(parent_idh,link_def_context,opts_create)
      self
    end

    def self.port_link_ref(port_link_ref_info)
      p = port_link_ref_info # for succinctness
      "#{p[:assembly_template_ref]}--#{p[:in_node_ref]}-#{p[:in_port_ref]}--#{p[:out_node_ref]}-#{p[:out_port_ref]}"
    end

    # TODO: deprecate after removing v1 assembly export adaptor
    def self.ref_from_ids(input_id,output_id)
      ref_from_ids_for_service_instances(input_id,output_id)
    end

    private

    # TODO: possibly change to using refs for service_instances like do for assembly templates
    def self.ref_from_ids_for_service_instances(input_id,output_id)
      "port_link:#{input_id}-#{output_id}"
    end

    def self.create_from_links_hash(target_idh,links_to_create,opts={})
      override_attrs = opts[:override_attrs]||{}
      rows = links_to_create.map do |link|
        ref = ref_from_ids_for_service_instances(link[:input_id],link[:output_id])
        {
          input_id: link[:input_id],
          output_id: link[:output_id],
          datacenter_datacenter_id: target_idh.get_id(),
          ref: ref
        }.merge(override_attrs)
      end
      create_opts = {returning_sql_cols: [:id,:input_id,:output_id]}
      port_link_mh = target_idh.create_childMH(:port_link)
      # TODO: push in use of :c into create_from_rows
      create_from_rows(port_link_mh,rows,create_opts).map{|hash|new(hash,port_link_mh[:c])}
    end

    def get_link_def_context?(parent_idh)
      self.class.get_link_def_context?(parent_idh,self)
    end
    def self.get_link_def_context?(parent_idh,port_link_hash)
      ret = nil
      sp_hash = {
        cols: [:id,:group_id,:display_name,:component_type,:direction,:link_type,:link_def_info,:node_node_id],
        filter: [:oneof, :id, [port_link_hash[:input_id],port_link_hash[:output_id]]]
      }
      ports_with_link_def_info = get_objs(parent_idh.createMH(:port),sp_hash)
      local_port_cmp_rows = ports_with_link_def_info.select{|r|(r[:link_def]||{})[:local_or_remote] == "local"}
      return ret if local_port_cmp_rows.empty?
      local_port_cmp_info = local_port_cmp_rows.first #all elements wil agree on the parts aside from link_def_link

      remote_port_cmp_rows = ports_with_link_def_info.select{|r|r[:id] != local_port_cmp_info[:id]}
      if remote_port_cmp_rows.empty?
        raise Error.new("Unexpected result that a remote port cannot be found")
      end
      remote_port_cmp_info = remote_port_cmp_rows.first

      return ret unless local_port_cmp_info[:link_type] == remote_port_cmp_info[:link_type]
      # find the matching link_def_link
      remote_cmp_type = remote_port_cmp_info[:component_type]

      # look for matching link
      components_coreside = (local_port_cmp_info[:node_node_id] == remote_port_cmp_info[:node_node_id])
      match = local_port_cmp_rows.find do |r|
        possible_link = r[:link_def_link]||{}
        if possible_link[:remote_component_type] == remote_cmp_type
          if components_coreside
            possible_link[:type] == "internal"
          else
            possible_link[:type] == "external"
          end
        end
      end
      return ret unless match

      # get remote component
      sp_hash = {
        cols: [:id,:group_id,:display_name,:node_node_id,:component_type,:implementation_id,:extended_base],
        filter: [:and,Component::Instance.filter(remote_port_cmp_info.component_type,remote_port_cmp_info.title?()),
                 [:eq,:node_node_id,remote_port_cmp_info[:node_node_id]]
                   ]
      }
      local_cmp = local_port_cmp_info[:component]
      rows = Model.get_objs(local_cmp.model_handle(),sp_hash)
      if rows.size == 1
        remote_cmp = rows.first
      elsif rows.empty?
        raise Error.new("Unexpected that no remote component found")
      else
        raise Error.new("Unexpected that getting remote port link component does not return unique element")
      end
      link_def_link = match[:link_def_link].merge!(local_component_type: local_cmp[:component_type])

      LinkDef::Context.create(link_def_link,[{component: local_cmp},{component: remote_cmp}])
    end
  end

  class PortLinkError < ErrorUsage
  end
end
