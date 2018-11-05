#
# Copyright (C) 2010-2016 dtk contributors
#
# This file is part of the dtk project.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
module DTK; class Assembly; class Instance
  module Get
    require_relative('get/attribute')
  end
  module GetMixin
    include Get::AttributeMixin

    def get_objs(sp_hash, opts = {})
      super(sp_hash, opts.merge(model_handle: model_handle.createMH(:assembly_instance)))
    end

    # get associated task template
    def get_parent
      Template.create_from_component(get_obj_helper(:instance_parent, :assembly_template))
    end

    def get_target
      get_obj_helper(:target, :target)
    end

    def get_target_idh
      id_handle.get_parent_id_handle_with_auth_info
    end

    #### get methods around attribute mappings
    def get_augmented_attribute_mappings
      # TODO: once field assembly_id is always populated on attribute.link, can do simpler query
      ret = []
      sp_hash = {
        cols: [:id, :group_id],
        filter: [:eq, :assembly_id, id]
      }
      port_links = Model.get_objs(model_handle(:port_link), sp_hash)
      filter = [:or, [:oneof, :port_link_id, port_links.map(&:id)], [:eq, :assembly_id, id]]
      AttributeLink.get_augmented(model_handle(:attribute_link), filter)
    end
    #### end: get methods around attribute mappings

    #### get methods around components

    def get_component_info_for_action_list(opts = {})
      get_field?(:display_name)
      assembly_source = { type: 'assembly', object: hash_subset(:id, :display_name) }
      component_instances = get_objs_helper(:instance_component_list, :nested_component, opts.merge(augmented: true))
      Component::Instance.add_title_fields?(component_instances)
      Component::Instance.add_action_defs!(component_instances)
      Component::Instance.update_components_on_remote_nodes!(component_instances, self)
      ret = opts[:add_on_to] || opts[:seed] || []
      component_instances.each { |r| ret << r.merge(source: assembly_source) }
      ret
    end

    def get_peer_component_instances(cmp_instance)
      sp_hash = {
        cols: [:id, :group_id, :display_name, :component_type],
        filter: [:and, [:eq, :ancestor_id, cmp_instance.get_field?(:ancestor_id)],
                 [:eq, :assembly_id, id],
                 [:neq, :id, cmp_instance.id]]
      }
      Component::Instance.get_objs(model_handle(:component_instance), sp_hash)
    end

    def get_component_instances(opts = {})
      sp_hash = {
        cols: opts[:cols] || [:id, :group_id, :display_name, :component_type],
        filter: [:eq, :assembly_id, id]
      }
      Component::Instance.get_objs(model_handle(:component_instance), sp_hash)
    end

    def get_nodes_with_components_and_their_attributes
      ndx_nodes = get_nodes.inject({}) { |h, node| h.merge(node.id => node) }

      sp_hash = sp_cols(:components_and_their_attrs).filter(:oneof, :id, ndx_nodes.keys)
      Node.get_objs(model_handle(:node), sp_hash).each do |row|
        if component = row[:component]
          node_id = row.id
          components = ndx_nodes[node_id][:components] ||= []
          unless matching_component = components.find { |cmp| cmp[:id] == component.id } 
            matching_component = component.merge(attributes: [])
            components << matching_component
          end
          if attr = row[:attribute]
            matching_component[:attributes] << attr
          end
        end
      end
      ndx_nodes.values
    end

    def get_augmented_components(opts = Opts.new)
      ret  = []
      rows = get_objs(cols: [:instance_nodes_and_cmps_summary_with_namespace])

      if opts[:filter_proc]
        rows.reject! { |r| !opts[:filter_proc].call(r) }
      elsif ! (opts[:filter_component] || '').empty?
        filter_component = opts[:filter_component]
        rows.reject! { |r| r[:nested_component].display_name_print_form != filter_component }
      end

      return ret if rows.empty?

      components = []
      rows.each do |r|
        if cmp = r[:nested_component]
          cmp.merge!(r.hash_subset(:node))
          cmp[:module_namespace] = r[:namespace][:display_name]

          # if component in service instance is edited it will have assembly branch version
          # we have to use ancestor branch version in list-components
          if ModuleVersion.assembly_module_version?(cmp[:version])
            module_branch   = r[:module_branch]
            ancestor_branch = module_branch.get_ancestor_branch?
            cmp[:version]   = ancestor_branch[:version] if ancestor_branch[:version]
          end

          # add node and namespace hash information to component hash
          components << cmp #.merge(r.hash_subset(:node)) #.merge!(r.hash_subset(:namespace)))
        end
      end

      if opts.array(:detail_to_include).include?(:component_dependencies)
        Dependency::All.augment_component_instances!(self, components, Opts.new(ret_statisfied_by: true))
      end
      components
    end

    #### end: get methods around components

    #### get methods around dependent modules and  module refs


    def get_dependent_module_refs_array
      # This returns an array of ModuleRef objects
      DependentModule.get_dependent_module_refs_array(self)
    end

    def get_common_module_locked_module_refs
      LockedModuleRefs::CommonModule.get(self)
    end

    #### end: get methods around component modules

    #### get methods around nodes
    # opts can have keys
    #  :cols
    #  :remove_node_groups
    #  :remove_assembly_wide_node
    def get_leaf_nodes(opts = {})
      get_nodes__expand_node_groups(opts.merge(remove_node_groups: true))
    end

    def get_nodes__expand_node_groups(opts = {})
      cols = opts[:cols] || Node.common_columns

      node_or_ngs = get_nodes(*cols)
      if opts[:remove_assembly_wide_node]
        node_or_ngs.reject!{ |n| n.is_assembly_wide_node? }
      end

      nodes = NodeGroup.expand_with_node_group_members?(node_or_ngs, opts)
      nodes.each{ |node| node.update_object!(:ng_member_deleted) }

      nodes
    end

    def get_node_groups(opts = {})
      cols = opts[:cols] || Node.common_columns
      node_or_ngs = get_nodes(*cols)
      NodeGroup.get_node_groups?(node_or_ngs)
    end

    def get_node?(filter)
      sp_hash = {
        cols: [:id, :display_name],
        filter: [:and, [:eq, :assembly_id, id], filter]
      }
      rows = Model.get_objs(model_handle(:node), sp_hash)
      if rows.size > 1
        Log.error("Unexpected that more than one row returned for filter (#{filter.inspect})")
        return nil
      end
      rows.first
    end

    def get_node_by_name?(node_name)
      get_node?([:eq, :display_name, node_name])
    end

    # TODO: rename to reflect that not including node group members, just node groups themselves and top level nodes
    # This is equivalent to saying that this does not return target_refs
    def get_nodes(*alt_cols)
      self.class.get_nodes([id_handle], *alt_cols)
    end
    #### end: get methods around nodes

    #### end: get methods around ports
    # augmented with node, :component  and link def info
    def get_augmented_ports(opts = {})
      ndx_ret = {}
      ret = get_objs(cols: [:augmented_ports]).map do |r|
        link_def = r[:link_def]
        if link_def.nil? || (link_def[:link_type] == r[:port].link_def_name)
          if get_augmented_ports__matches_on_title?(r[:nested_component], r[:port])
            r[:port].merge(r.slice(:node, :nested_component, :link_def))
          end
        end
      end.compact
      if opts[:mark_unconnected]
        get_augmented_ports__mark_unconnected!(ret, opts)
      end
      ret
    end

    # TODO: more efficient if can do the 'title' match on sql side
    def get_augmented_ports__matches_on_title?(component, port)
      ret = true
      if cmp_title = ComponentTitle.title?(component)
        ret = (cmp_title == port.title?)
      end
      ret
    end
    private :get_augmented_ports__matches_on_title?

    # TODO: there is a field on ports :connected, but it is not correctly updated so need to get ports links to find out what is connected
    def get_augmented_ports__mark_unconnected!(aug_ports, _opts = {})
      port_links = get_port_links
      connected_ports =  port_links.map { |r| [r[:input_id], r[:output_id]] }.flatten.uniq
      aug_ports.each do |r|
        if r[:direction] == 'input'
          r[:unconnected] = !connected_ports.include?(r[:id])
        end
      end
    end
    private :get_augmented_ports__mark_unconnected!
    #### end: get methods around ports

    #### get methods around service add ons

    def get_augmented_service_add_ons
      get_objs_helper(:aug_service_add_ons_from_instance, :service_add_on, augmented: true)
    end

    def get_augmented_service_add_on(add_on_name)
      filter_proc = lambda { |sao| sao[:service_add_on][:display_name] == add_on_name }
      get_obj_helper(:aug_service_add_ons_from_instance, :service_add_on, filter_proc: filter_proc, augmented: true)
    end

    #### end: get methods around service add ons
    def get_tasks(opts = {})
      rows = get_objs(cols: [:tasks])
      if opts[:filter_proc]
        rows.reject! { |r| !opts[:filter_proc].call(r) }
      end
      rows.map { |r| r[:task] }
    end

    #### get methods around task templates

    def get_task_templates(opts = {})
      Task::Template.get_task_templates(self, opts)
    end

    #### end: get methods around task templates

    #### get methods around tasks
    def get_last_task_run_status?
      self.class.get_ndx_last_task_run_status([self], model_handle).values.first
    end

    #### end: get methods around tasks

    def get_service_instance_branch
      AssemblyModule::Service.get_service_instance_branch(self)
    end

    def get_sub_assemblies
      self.class.get_sub_assemblies([id_handle])
    end
  end

  module GetClassMixin
    def get_objs(mh, sp_hash, opts = {})
      if mh[:model_name] == :assembly_instance
        get_these_objs(mh, sp_hash, opts)
      else
        super
      end
    end

    def get(assembly_mh, opts = {})
      target_idhs = (opts[:target_idh] ? [opts[:target_idh]] : opts[:target_idhs])
      target_filter = (target_idhs ? [:oneof, :datacenter_datacenter_id, target_idhs.map(&:get_id)] : [:neq, :datacenter_datacenter_id, nil])
      filter = [:and, [:eq, :type, 'composite'], target_filter, opts[:filter]].compact
      sp_hash = {
        cols: opts[:cols] || [:id, :group_id, :display_name, :ref],
        filter: filter
      }
      get_these_objs(assembly_mh, sp_hash, keep_ref_cols: true) #:keep_ref_cols=>true just in case ref col
    end

    def get_info__flat_list(assembly_mh, opts = {})
      target_idh = opts[:target_idh]
      target_filter = (target_idh ? [:eq, :datacenter_datacenter_id, target_idh.get_id] : [:neq, :datacenter_datacenter_id, nil])
      filter = [:and, [:eq, :type, 'composite'], target_filter, opts[:filter]].compact
      col, needs_empty_nodes = list_virtual_column?(opts[:detail_level])
      cols = [:id, :ref, :display_name, :group_id, :component_type, :version, :created_at, :specific_type, col].compact
      ret = get(assembly_mh, { cols: cols }.merge(opts))
      return ret unless needs_empty_nodes

      # add in in assembly nodes without components on them
      nodes_ids = ret.map { |r| (r[:node] || {})[:id] }.compact
      sp_hash = {
        cols: [:id, :display_name, :component_type, :version, :instance_nodes_and_assembly_template],
        filter: filter
      }
      assembly_empty_nodes = get_objs(assembly_mh, sp_hash).reject { |r| nodes_ids.include?((r[:node] || {})[:id]) }
      ret + assembly_empty_nodes
    end

    #### get methods around nodes
    def get_nodes(assembly_idhs, *alt_cols)
      ret = []
      return ret if assembly_idhs.empty?
      sp_hash = {
        cols: [:id, :group_id, :node_node_id],
        filter: [:oneof, :assembly_id, assembly_idhs.map(&:get_id)]
      }
      ndx_nodes = {}
      component_mh = assembly_idhs.first.createMH(:component)
      get_objs(component_mh, sp_hash).each do |cmp|
        ndx_nodes[cmp[:node_node_id]] ||= true
      end

      cols = ([:id, :display_name, :group_id, :type] + alt_cols).uniq
      sp_hash = {
        cols: cols,
        filter: [:and, filter_out_target_refs,
                 [:or, [:oneof, :id, ndx_nodes.keys],
                  #to catch nodes without any components
                  [:oneof, :assembly_id, assembly_idhs.map(&:get_id)]]
                   ]
      }
      node_mh = assembly_idhs.first.createMH(:node)
      get_objs(node_mh, sp_hash)
    end

    # TODO: rename to reflect that not including node group members, just node groups themselves and top level nodes
    # This is equivalent to saying that this does not return target_refs
    def get_nodes_simple(assembly_idhs, opts = {})
      ret = []
      return ret if assembly_idhs.empty?
      sp_hash = {
        cols: opts[:cols] || [:id, :display_name, :group_id, :type, :assembly_id],
        filter: [:oneof, :assembly_id, assembly_idhs.map(&:get_id)]
      }
      node_mh = assembly_idhs.first.createMH(:node)
      ret = get_objs(node_mh, sp_hash)
      unless opts[:ret_subclasses]
        ret
      else
        ret.map do |r|
          r.is_node_group? ? r.id_handle.create_object(model_name: :node_group).merge(r) : r
        end
      end
    end
    #### end: get methods around nodes

    #### get methods around tasks

    # indexed by assembly id
    def get_ndx_last_task_run_status(assembly_rows, assembly_mh)
      ret = {}
      sp_hash = {
        cols: [:id, :started_at, :assembly_id, :status, :display_name],
        filter: [:oneof, :assembly_id, assembly_rows.map { |r| r[:id] }]
      }
      ndx_task_rows = {}
      get_objs(assembly_mh.createMH(:task), sp_hash).each do |task|
        next unless task[:started_at]
        assembly_id = task[:assembly_id]
        if pntr = ndx_task_rows[assembly_id]
          if task[:started_at] > pntr[:started_at]
            ndx_task_rows[assembly_id] =  task.slice(:status, :started_at, :display_name)
          end
        else
          ndx_task_rows[assembly_id] = task.slice(:status, :started_at, :display_name)
        end
      end
      assembly_rows.each do |r|
        if last_task_run_status = ndx_task_rows[r[:id]] && ndx_task_rows[r[:id]][:display_name] && ndx_task_rows[r[:id]][:status]
          ret[r.id] = { last_task_run_status: last_task_run_status, last_action: ndx_task_rows[r[:id]][:display_name] }
        end
      end
      ret
    end

    #### end: get methods around tasks

    def get_sub_assemblies(assembly_idhs)
      ret = []
      return ret if assembly_idhs.empty?
      sp_hash = {
        cols: [:id, :group_id, :display_name],
        filter: [:and, [:oneof, :assembly_id, assembly_idhs.map(&:get_id)], [:eq, :type, 'composite']]
      }
      get_objs(assembly_idhs.first.createMH, sp_hash).map(&:copy_as_assembly_instance)
    end

    private

    def filter_out_target_refs
      @filter_out_target_ref ||= [:and] + Node::TargetRef.types.map { |t| [:neq, :type, t] }
    end
  end
end; end; end
