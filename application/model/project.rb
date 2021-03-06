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
  class Project < Model
    def self.create_new_project(model_handle, name, type)
      sp_hash = {
        cols: [:id],
        filter: [:eq, :display_name, name]
      }
      unless get_objs(model_handle, sp_hash).empty?
        fail Error.new("project with name #{name} exists already")
      end
      row = {
        display_name: name,
        ref: name,
        type: type
      }
      create_from_row(model_handle, row)
    end

    def self.get_all(model_handle)
      sp_hash = { cols: [:id, :display_name, :group_id, :type] }
      get_objs(model_handle, sp_hash)
    end

    # TODO: this wil be deprecated, but also looks like it gets wrong components
    def get_implementaton_tree(opts = {})
      sp_hash = { cols: [:id, :display_name, :type, :implementation_tree] }
      unravelled_ret = get_objs(sp_hash)
      ret_hash = {}

      i18n = get_i18n_mappings_for_models(:component)
      unravelled_ret.each do |r|
        # TODO: hack until determine right way to treat relationship between component and implementation versions
        index = r[:component][:component_type]
        cmp = ret_hash[index]
        # TODO: dont think ids are used; but for consistency using lowest id instance
        if cmp.nil? || r[:component][:id] < cmp[:id]
          cmp = ret_hash[index] = r[:component].materialize!(Component.common_columns())
          # TODO: see if cleaner way to put in i18n names
          cmp[:name] = i18n_string(i18n, :component, cmp[:name])
        end
        impls = cmp[:implementations] ||= {}
        # TODO: this is hack taht needs fixing
        impls[r[:implementation][:id]] ||= r[:implementation].merge(version: r[:component][:version])
      end
      ret = ret_hash.values.map { |ct| ct.merge(implementations: ct[:implementations].values) }
      return ret unless opts[:include_file_assets]

      impl_idhs = ret.flat_map { |ct| ct[:implementations].map(&:id_handle) }
      indexed_asset_files = Implementation.get_indexed_asset_files(impl_idhs)
      ret.each { |ct| ct[:implementations].each { |impl| impl.merge!(file_assets: indexed_asset_files[impl[:id]]) } }
      ret
    end

    def get_module_tree(opts = {})
      ndx_ret = {}
      sp_hash = { cols: [:id, :display_name, :type, :module_tree] }
      unravelled_ret = get_objs(sp_hash)
      i18n = get_i18n_mappings_for_models(:component)
      unravelled_ret.each do |r|
        impl_id = r[:implementation][:id]
        cmps = (ndx_ret[impl_id] ||= r[:implementation].merge(components: []))[:components]
        if r[:component]
          cmp = r[:component].materialize!(Component.common_columns())
          # TODO: see if cleaner way to put in i18n names
          cmp[:name] = i18n_string(i18n, :component, cmp[:name])
          cmps << cmp
        end
      end
      ret = ndx_ret.values
      return ret unless opts[:include_file_assets]

      impl_idhs = ret.map(&:id_handle)
      indexed_asset_files = Implementation.get_indexed_asset_files(impl_idhs)
      ret.each { |impl| impl.merge!(file_assets: indexed_asset_files[impl[:id]] || []) }
      ret
    end

    def get_target_tree
      # get and index node group members (index is [target_id][node_group_id]
      ndx_ng_members = {}
      get_objs(cols: [:id, :node_group_relations]).each do |r|
        pntr = ndx_ng_members[r[:target][:id]] ||= {}
        ng_id = r[:node_group_relation][:node_group_id]
        (pntr[ng_id] ||= []) << r[:node_group_relation][:node_id]
      end

      unravelled_ret = get_objs(cols: [:id, :display_name, :type, :target_tree])
      ret_hash = {}
      unravelled_ret.each do |r|
        target_id = r[:target][:id]
        unless target = ret_hash[target_id]
          target = ret_hash[target_id] ||= r[:target].materialize!(Target.common_columns()).merge(model_name: 'target')
        end
        nodes = target[:nodes] ||= {}
        next unless r[:node]
        unless node = nodes[r[:node][:id]]
          node = nodes[r[:node][:id]] = r[:node].materialize!(Node.common_columns())
          if node.is_node_group?
            node_group_members = (ndx_ng_members[target_id] || {})[node[:id]] || []
            node.merge!(node_group_members: node_group_members)
          end
        end
        components = node[:components] ||= {}
        components[r[:component][:id]] = r[:component].materialize!(Component.common_columns()) if r[:component]
      end
      ret_hash.values.map do |t|
        nodes = t[:nodes].values.map do |n|
          n.merge(components: n[:components].values)
        end
        t.merge(nodes: nodes)
      end
    end

    def destroy_and_delete_nodes
      targets = get_objs(cols: [:targets]).map { |r| r[:target] }
      targets.each(&:destroy_and_delete_nodes)
    end

    def delete_projects_repo_branches
      sp_hash = {
        cols: [:repo, :branch],
        filter: [:eq, :project_project_id, id()]
      }
      impl_mh = model_handle(:implementation)
      impls = Model.get_objs(impl_mh, sp_hash)
      impls.each { |impl| Repo.delete(implementation: impl) }
    end
  end
end