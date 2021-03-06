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
module DTK
  class Assembly
    module ListMixin
      # TODO: clean up so when this method called is can only be integer or nil
      def info(node_id = nil, component_id = nil, attribute_id = nil, opts = {})
        is_template = is_a?(Template)
        opts.merge!(is_template: true) if is_template

        nested_virtual_attr = (is_template ? :template_nodes_and_cmps_summary : :instance_nodes_and_cmps_summary)
        sp_hash = {
          cols: [:id, :display_name, :component_type, nested_virtual_attr]
        }
        assembly_rows = get_objs(sp_hash)
        Instance.add_last_task_run_status!(assembly_rows, model_handle())

        if (node_id.to_s.empty? && component_id.to_s.empty? && attribute_id.to_s.empty?)
          nodes_info = (is_template ? get_nodes() : get_nodes__expand_node_groups(remove_node_groups: true))
          nodes_info.reject! { |n| Node.is_assembly_wide_node?(n) } if opts[:remove_assembly_wide_node]
          assembly_rows.first[:nodes] = nodes_info.sort { |a, b| a[:display_name] <=> b[:display_name] }
        end

        # filter nodes by node_id if node_id is provided in request
        unless (node_id.nil? || node_id.empty?)
          sp_hash = {
            cols: [:id, :display_name, :admin_op_status, :os_type, :external_ref, :type, :ordered_component_ids],
            filter: [:and, [:eq, :id, node_id]]
          }
          node = Model.get_obj(model_handle(:node), sp_hash)
          assembly_rows.first[:node] = node

          assembly_rows = assembly_rows.select { |node| node[:node][:id] == node_id.to_i }
          opts.merge!(component_info: true)
        end

        # filter nodes by component_id if component_id is provided in request
        unless (component_id.nil? || component_id.empty?)
          assembly_rows = assembly_rows.select { |node| node[:nested_component][:id] == component_id.to_i }
          opts.merge!(component_info: true, attribute_info: true)
        end

        # load attributes for assembly
        attr_rows = self.class.get_default_component_attributes(model_handle(), assembly_rows)

        # filter attributes by attribute_name if attribute_name is provided in request
        if attribute_id
          attr_rows.reject! { |attr| attr[:id] != attribute_id.to_i }
        end

        # reconfigure response fields that will be returned to the client
        opts_list = { print_form: true, sanitize: true }.merge(opts)

        if is_a?(Instance)
          assembly_templates = assembly_rows.map { |a| a[:assembly_template] unless Workspace.is_workspace?(a) }.compact
          unless assembly_templates.empty?
            Template.augment_with_namespaces!(assembly_templates)
            opts_list[:include_namespaces] ||= true
          end
        end

        ret = self.class.list_aux(assembly_rows, attr_rows, opts_list).first
        if is_a?(Template)
          [:op_status, :last_task_run_status].each { |k| ret.delete(k) }
        end

        ret[:nodes].each do |node|
          node.reject! { |k| ![:display_name, :node_properties, :components].include?(k) }
        end

        # TODO: temp until get removes this attribute
        ret.delete(:execution_status)
        ret
      end

      def pretty_print_name(_opts = {})
        self.class.pretty_print_name(self, opts = {})
      end
    end

    module ListClassMixin
      def list_aux(assembly_rows, attr_rows = [], opts = {})
        ndx_attrs = {}

        if opts[:attribute_info]
          attr_rows.each do |attr|
            if (attr[:attribute_value] && !attr[:attribute_value].empty?)
              (ndx_attrs[attr[:component_component_id]] ||= []) << attr
            end
          end
        end

        ndx_ret = {}
        pp_opts = Aux.hash_subset(opts, [:no_module_prefix])
        assembly_template_opts = { version_suffix: true }
        if opts[:include_namespaces]
          assembly_template_opts.merge!(include_namespace: true, service_module_context_path: true)
        end
        assembly_rows.each do |r|
          last_task_run_status = r[:last_task_run_status]
          last_action = r[:last_action]
          service_contexts = ServiceAssociations.get_parents(r)
          # using join(',') rather than join(', ') so can cut and paste to put in stage command line -c option"
          service_context = (service_contexts.empty? ? nil : service_contexts.map(&:display_name).join(','))
          pntr = ndx_ret[r[:id]] ||= r.prune_with_values(
              display_name: r.pretty_print_name(pp_opts),
              service_context: service_context,
              last_task_run_status: last_task_run_status,
              last_action: last_action,
              # TODO: will deprecate :execution_status after removing it from smoketests
              execution_status: last_task_run_status || 'staged',
              ndx_nodes: {}
          )

          if module_branch_id = r[:module_branch_id]
            pntr[:module_branch_id] ||= module_branch_id
          end

          # TODO: wil deprecate settig :target once we make sure not used anywhere
          if target = r[:target]
            pntr.merge!(target_model_handle: target.model_handle)
            if target[:iaas_properties]
              sec_group_set = target[:iaas_properties][:security_group_set]
              target[:iaas_properties][:security_group] ||= sec_group_set.join(',') if sec_group_set
            end
            pntr[:target] ||= target[:display_name]
            opts.merge!(target: target)
          end

          if version = pretty_print_version(r)
            pntr.merge!(version: version)
          end

          if template = r[:assembly_template]
            # just triggers for assembly instances; indicates the assembly template that spawned it
            pntr.merge!(assembly_template: Template.pretty_print_name(template, assembly_template_opts))
          end

          if created_at = r[:created_at]
            pntr.merge!(created_at: created_at)
          end

          if specific_type = r[:specific_type]
            pntr.merge!(specific_type: specific_type)
          end

          if node = format_node!(pntr[:ndx_nodes], r[:node], opts)
            format_components_and_attributes(node, r, ndx_attrs, opts)
          end

          # if node group take only group members
          if r[:node] && r[:node].is_node_group?() && !opts[:is_template]
            unless opts[:only_node_group_info]
              r[:nodes] = r.get_nodes__expand_node_groups(remove_node_groups: true, add_group_member_components: true) 
              r[:nodes].sort! { |a, b| a[:display_name] <=> b[:display_name] }
              opts.merge!(add_group_member_components: true)
            end
          end

          if r[:nodes]
            r[:nodes].each do |n|
              format_node!(pntr[:ndx_nodes], n, opts)
              process_node_group_memeber_components(pntr[:ndx_nodes], n, opts) if opts[:add_group_member_components]
            end
          end
        end

        target_model_handle = ndx_ret.values.first && ndx_ret.values.first[:target_model_handle]
        default_target = target_model_handle && Target::Instance.get_default_target(target_model_handle, ret_singleton_target: true, prune_builtin_target: true)

        unsorted = ndx_ret.values.map do |r|
          r[:display_name] = r[:display_name] + "*" if default_target and default_target.display_name == r.display_name

          nodes = r[:ndx_nodes].values
          nodes.reject! { |n| Node.is_assembly_wide_node?(n) } if opts[:remove_assembly_wide_node]
          # TODO: this is misleading since admin not op status returned
          summary_node_status = (summary_node_status(:admin, nodes, r[:last_task_run_status]) if respond_to?(:summary_node_status))
          r.merge(op_status: summary_node_status, nodes: nodes).slice(:id, :display_name, :op_status, :last_task_run_status, :last_action, :service_context, :execution_status, :module_branch_id, :version, :assembly_template, :target, :nodes, :created_at, :keypair, :security_groups)
        end

        sanitize!(unsorted) if opts[:sanitize]

        unsorted.sort { |a, b| a[:display_name] <=> b[:display_name] }
      end

      private

      def sanitize!(output)
        output.each do |assembly|
          (assembly[:nodes] || []).each { |node_hash| Node.sanitize!(node_hash) }
        end
      end

      def list_aux__component_template(r)
        r[:component_template] || r[:nested_component] || {}
      end

      # format node adds :node_properties and empty array to ndx_nodes
      def format_node!(ndx_nodes, raw_node, opts = {})
        if raw_node
          target       = opts[:target]
          node_name    = raw_node[:display_name]
          external_ref = nil

          format_current_node = (!raw_node.is_node_group?() || opts[:only_node_group_info])
          if ndx_nodes[node_name].nil? && (format_current_node || opts[:is_template]) #!raw_node.is_node_group?()
            if node_ext_ref = raw_node[:external_ref]
              external_ref = node_external_ref_print_form(node_ext_ref, opts)
              # remove :git_authorized
              external_ref = external_ref.inject({}) do |h, (k, v)|
                k == :git_authorized ? h : h.merge(k => v)
              end
            end

            node_properties = {
              node_id: raw_node[:id],
              os_type: raw_node[:os_type],
              admin_op_status: raw_node[:admin_op_status]
            }
            node_properties.merge!(external_ref) if external_ref

            if target
              iaas_properties = target[:iaas_properties]
              node_properties[:keypair] ||= iaas_properties[:keypair]
              # substitute node[:security_group] or node[:security_group_set] with node[:security_groups]
              check_node_security_groups!(node_properties)
              node_properties[:security_groups] ||= iaas_properties[:security_group]
            end

            node_properties.reject! { |_k, v| v.nil? }
            ndx_nodes[node_name] = raw_node.merge(components: [], node_properties: node_properties)
          end

          ndx_nodes[node_name]
        end
      end

      def process_node_group_memeber_components(ndx_nodes, raw_node, _opts = {})
        if components = raw_node[:components]
          cmp_names = components.map { |cmp| cmp[:display_name] }
          node_name = raw_node[:display_name]
          ndx_nodes[node_name].merge!(components: cmp_names)
        end
      end

      # substitute node[:security_group] or node[:security_group_set] with node[:security_groups]
      # not deleting any keys just changing the name
      def check_node_security_groups!(node_properties)
        if security_group = node_properties.delete(:security_group)
          node_properties[:security_groups] = security_group
        elsif security_group_set = node_properties.delete(:security_group_set)
          node_properties[:security_groups] = security_group_set.join(',')
        end
      end

      def node_external_ref_print_form(node_ext_ref, opts = {})
        ret = node_ext_ref.class.new()
        has_print_form = opts[:print_form]
        node_ext_ref.each_pair do |k, v|
          if [:secret, :key].include?(k)
            # omit
          elsif not has_print_form
            ret[k] = v
          else
            if [:dns_name].include?(k)
              # no op
            elsif k == :private_dns_name && v.is_a?(Hash)
              ret[k] = v.values.first
            else
              ret[k] = v
            end
          end
        end
        ret
      end

      def format_components_and_attributes(node, raw_row, ndx_attrs, opts)
        cmp_hash = list_aux__component_template(raw_row)
        if cmp_type =  cmp_hash[:component_type] && cmp_hash[:component_type].gsub(/__/, '::')
          cmp =
            if opts[:component_info]
              version = ModuleBranch.version_from_version_field(cmp_hash[:version])
              {
              component_name: cmp_type,
              component_id: cmp_hash[:id],
              basic_type: cmp_hash[:basic_type],
              description: cmp_hash[:description],
              version: version
            }
            elsif not ndx_attrs.empty?
              { component_name: cmp_type }
            else
              cmp_type
            end

          if attrs = ndx_attrs[list_aux__component_template(raw_row)[:id]]
            processed_attrs = attrs.map do |attr|
              proc_attr = { attribute_name: attr[:display_name], value: attr[:attribute_value] }
              proc_attr[:override] = true if attr[:is_instance_value]
              proc_attr
            end
            cmp.merge!(attributes: processed_attrs) if cmp.is_a?(Hash)
          end
          node[:components] << cmp
        end
        node[:components]
      end
    end
  end
end
