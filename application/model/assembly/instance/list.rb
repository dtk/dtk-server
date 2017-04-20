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
module DTK; class Assembly::Instance
  module List
    require_relative('list/nodes')
    require_relative('list/actions')

    module ClassMixin
      def list_with_workspace(assembly_mh, opts = {})
        get(assembly_mh, opts)
      end

      def list(assembly_mh, opts = {})
        assembly_mh = assembly_mh.createMH(:assembly_instance) # to insure right mh type
        assembly_rows = get_info__flat_list(assembly_mh, opts)

        if opts[:detail_level].nil?
          if opts[:include_namespaces]
            Log.error('Unexpected that opts[:include_namespaces] is true')
          end
          list_aux__no_details(assembly_rows)
        else
          get_attrs = [opts[:detail_level]].flatten.include?('attributes')
          attr_rows = get_attrs ? get_default_component_attributes(assembly_mh, assembly_rows) : []
          add_last_task_run_status!(assembly_rows, assembly_mh)

          if opts[:include_namespaces]
            assembly_templates = assembly_rows.map { |a| a[:assembly_template] }.compact
            Template.augment_with_namespaces!(assembly_templates)
          end
          list_aux(assembly_rows, attr_rows, opts)
        end
      end

      def pretty_print_name(assembly, _opts = {})
        assembly.get_field?(:display_name)
      end

      def add_last_task_run_status!(assembly_rows, assembly_mh)
        ndx_status = get_ndx_last_task_run_status(assembly_rows, assembly_mh)
        assembly_rows.each do |r| 
          if last_task_run_status = ndx_status[r.id]
            r[:last_task_run_status] = last_task_run_status
          end
        end
        assembly_rows
      end

      private

      def list_aux__no_details(assembly_rows)
        assembly_rows.map do |r|
          r.prune_with_values(display_name: pretty_print_name(r))
        end
      end
    end

    module Mixin
      include Actions::Mixin
      include Nodes::Mixin

      def info_about(about, opts = Opts.new)
        case about
        when :attributes
          attributes = list_attributes(opts)
          fail ErrorNameDoesNotExist.new(opts[:attribute_id], :attribute) if opts[:raise_if_no_attribute] && attributes.empty?
          attributes
        when :components
          list_components(opts)
        when :nodes
          opts.merge!(cols: Node.common_columns + [:target])
          list_nodes(opts)
        when :modules
          list_component_modules(opts)
        when :tasks
          list_tasks(opts)
        else
          fail Error.new("TODO: not implemented yet: processing of info_about(#{about})")
        end
      end

      def list_attributes(opts = Opts.new)
        if opts[:settings_form]
          filter_proc = opts[:filter_proc]
          attrs_all_levels_struct = get_attributes_all_levels_struct(filter_proc)
          ServiceSetting::AttributeSettings::HashForm.render(attrs_all_levels_struct)
        else
          cols_to_get = (opts[:raw_attribute_value] ? [:display_name, :value] : [:id, :display_name, :value, :linked_to_display_form, :datatype, :name])
          ret = get_attributes_print_form_aux(opts).map do |a|
            Aux.hash_subset(a, cols_to_get)
          end.sort { |a, b| a[:display_name] <=> b[:display_name] }
          opts[:raw_attribute_value] ? ret.inject({}) { |h, r| h.merge(r[:display_name] => r[:value]) } : ret
        end
      end

      def list_component_modules(opts = Opts.new)
        opts_get = {}
        if get_branch_relationship_info = opts.array(:detail_to_include).include?(:version_info)
          opts.set_datatype!(:assembly_component_module)
          opts_get.merge!(get_branch_relationship_info: true)
        end

        unsorted_ret = get_component_modules(:recursive, opts_get)
        unsorted_ret.each do |r|
          module_branch = r[:module_branch]
          version       = module_branch[:version] if module_branch
          r[:full_name] = "#{r[:namespace_name]}:#{r[:display_name]}"

          if version.eql?('master') || version.match(/\A\d{1,2}\.\d{1,2}\.\d{1,2}\Z/)
            r[:display_version] = version
          else
            if ancestor_version = (module_branch.get_ancestor_branch?||{})[:version]
              r[:display_version] = ancestor_version
            end
          end

          if get_branch_relationship_info
            if r[:local_copy]
              if module_branch[:frozen]
                r[:update_saved] = "n/a"
              else
                branch_relationship     = r[:branch_relationship] || ''
                local_ahead_or_branchpt = branch_relationship.eql?(:local_ahead) || branch_relationship.eql?(:branchpoint)
                r[:update_saved] = !(r[:local_copy_diff] && local_ahead_or_branchpt)
              end
            end
          end
        end

        unsorted_ret.sort { |a, b| a[:display_name] <=> b[:display_name] }
      end


      def list_components(opts = Opts.new)
        aug_cmps      = get_augmented_components(opts)
        node_cmp_name = opts[:node_cmp_name]

        cmps_print_form = aug_cmps.map do |r|
          namespace      = r[:namespace]
          node_name      = "#{node_component_ref(r[:node])}/"
          version        = r[:version]
          hide_node_name = node_cmp_name || Node.is_assembly_wide_node?(r[:node])
          display_name   = "#{hide_node_name ? '' : node_name}#{Component::Instance.print_form(r, namespace)}"
          r.hash_subset(:id).merge(display_name: display_name, version: version)
        end

        sort = proc { |a, b| a[:display_name] <=> b[:display_name] }
        if opts.array(:detail_to_include).include?(:component_dependencies)
          opts.set_datatype!(:component_with_dependencies)
          list_components__with_deps(cmps_print_form, aug_cmps, sort)
        else
          opts.set_datatype!(:component)
          cmps_print_form.sort(&sort)
        end
      end

      def display_name_print_form(_opts = {})
        pretty_print_name
      end

      def print_includes
        ModuleRefs::Tree.create(self).hash_form
      end

      private

      def node_component_ref(node)
        # TODO: hard coding this to ec2
        NodeComponent.node_component_ref(:ec2, node.display_name)
      end

      def convert_to_component_print_form(aug_cmp, opts = Opts.new)
        node_cmp_name  = opts[:node_cmp_name]
        namespace      = aug_cmp[:namespace]
        node_name      = "#{node_component_ref(aug_cmp[:node])}/"
        hide_node_name = node_cmp_name || Node.is_assembly_wide_node?(aug_cmp[:node])
        display_name   = "#{hide_node_name ? '' : node_name}#{Component::Instance.print_form(aug_cmp, namespace)}"
        aug_cmp.hash_subset(:id).merge(display_name: display_name)
      end

      def list_tasks(_opts = {})
        tasks = []
        rows = get_objs(cols: [:tasks])
        rows.each do |row|
          task        = row[:task]
          task[:type] = task[:display_name]
          tasks << task
        end
        tasks.flatten
      end

      def list_components__with_deps(cmps_print_form, aug_cmps, main_table_sort)
        ndx_component_print_form = ret_ndx_component_print_form(aug_cmps, cmps_print_form)
        join_columns = OutputTable::JoinColumns.new(aug_cmps) do |aug_cmp|
          if deps = aug_cmp[:dependencies]
            ndx_els = {}
            deps.each do |dep|
              if depends_on = dep.depends_on_print_form?
                el = ndx_els[depends_on] ||= []
                sb_cmp_ids =  dep.satisfied_by_component_ids
                ndx_els[depends_on] += (sb_cmp_ids - el)
              end
            end
            ndx_els.map do |depends_on, sb_cmp_ids|
              satisfied_by = (sb_cmp_ids.empty? ? nil : sb_cmp_ids.map { |cmp_id| ndx_component_print_form[cmp_id] }.join(', '))
              { depends_on: depends_on, satisfied_by: satisfied_by }
            end
          end
        end
        OutputTable.join(cmps_print_form, join_columns, &main_table_sort)
      end

      def list_components__remove_node_property_components!(aug_cmps)
        node_property_cmps = CommandAndControl.node_property_component_names
        aug_cmps.reject!{ |cmp| node_property_cmps.include?(cmp[:component_type].gsub('__', '::')) }
      end

      def ret_ndx_component_print_form(aug_cmps, cmps_with_print_form)
        # has lookup that includes each satisfied_by_component
        ret = cmps_with_print_form.inject({}) { |h, cmp| h.merge(cmp[:id] => cmp[:display_name]) }

        # see if there is any components that are referenced but not in ret
        needed_cmp_ids = []
        aug_cmps.each do |aug_cmp|
          if deps = aug_cmp[:dependencies]
            deps.map do |dep|
              dep.satisfied_by_component_ids.each do |cmp_id|
                needed_cmp_ids << cmp_id if ret[cmp_id].nil?
              end
            end
          end
        end
        return ret if needed_cmp_ids.empty?
        additional_cmps = get_ndx_extra_component_display_names(needed_cmp_ids)
        additional_cmps.inject(ret) { |h, cmp| h.merge(cmp[:id] => cmp[:display_name]) }
      end

      # these can be components that are not in this
      def get_ndx_extra_component_display_names(cmp_ids)
        ret = {}
        sp_hash = {
          cols:   [:id, :group_id, :display_name, :node, :assembly_id],
          filter: [:oneof, :id, cmp_ids] 
        }
        aug_cmps = Component::Instance.get_objs(model_handle(:component_instance), sp_hash)
        return ret if aug_cmps.empty?

        ndx_cmps_to_assemblies = aug_cmps.inject({}) { |h, r| h.merge(r[:id] => r[:assembly_id]) }

        sp_hash = {
          cols:   [:id, :group_id, :display_name],
          filter: [:oneof, :id, aug_cmps.map { |aug_cmp| ndx_cmps_to_assemblies.values.uniq }]
        }
        ndx_assembly_names = Assembly::Instance.get_objs(model_handle, sp_hash).inject({}) do |h, r| 
          h.merge(r[:id] => r[:display_name]) 
        end
        
        aug_cmps.map do | aug_cmp |
          qualified_cmp_name = convert_to_component_print_form(aug_cmp)
          if assembly_id = ndx_cmps_to_assemblies[aug_cmp[:id]]
            unless assembly_id == id
              qualified_cmp_name = "#{qualified_cmp_name} (#{ndx_assembly_names[assembly_id]})"
            end
          end
          { id: aug_cmp[:id], display_name: qualified_cmp_name}
        end
      end

    end
  end
end; end
