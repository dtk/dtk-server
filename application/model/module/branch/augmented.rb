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
#
# Classes that encapsulate information for each module or moulde branch where is its location clone and where is its remotes
#
module DTK
  class ModuleBranch
    class Augmented < self
      subclass_model :module_branch_augmented, :module_branch, print_form: 'module_branch'

      def version
        self[:version]
      end
      
      def component_module?
        self[:component_module]
      end
      def component_module
        component_module? || raise_unexpected_nil('component_module?')
      end

      def component_module_name?
        if component_module = component_module?
          pp [:component_module, component_module]
          component_module.get_field?(:display_name)
        end
      end
      def component_module_name
        component_module_name? || raise_unexpected_nil('component_module_name?') 
      end

      def component_module
        component_module? || raise_unexpected_nil('component_module?')
      end

      def repo
        self[:repo] || raise_unexpected_nil('self[:repo]')
      end

      def branch_name
        self[:branch]  || raise_unexpected_nil('self[:branch]')
      end

      def implementation
        @implementation ||= get_implementation
      end

      # opts can have keys:
      #   :filter
      #   :donot_raise_error
      #   :include_repo_remotes
      def self.get_augmented_module_branch(parent_module, opts = {})
        ret = nil
        version       = (opts[:filter] || {})[:version] #version can be nil
        version_field = ModuleBranch.version_field(version) 
        sp_hash = {
          cols: [:display_name, :augmented_branch_info, :namespace]
        }
        module_rows = parent_module.get_objs(sp_hash).select do |r|
          r[:module_branch][:version] == version_field
        end

        if module_rows.size == 0
          unless opts[:donot_raise_error]
            fail ErrorUsage.new("Module #{parent_module.pp_module_name(version)} does not exist")
          end
          return ret
        end

        # aggregate by remote_namespace, filtering by remote_namespace if remote_namespace is given
        unless module_obj = aggregate_by_remote_namespace(module_rows, opts)
          fail ErrorUsage.new("The module (#{parent_module.pp_module_name(version)}) is not tied to namespace '#{opts[:filter][:remote_namespace]}' on the repo manager")
        end

        aug_module_branch = module_obj[:module_branch].merge(repo: module_obj[:repo], module_name: module_obj[:display_name], module_namespace: module_obj[:namespace][:display_name])

        if opts[:include_repo_remotes]
          aug_module_branch.merge!(repo_remotes: module_obj[:repo_remotes])
        end
        aug_module_branch.create_as_subclass_object(self)
      end

      def self.augment_with_repos!(module_branches)
        return module_branches if module_branches.empty?
        repo_mh = module_branches.first.model_handle(:repo)
        sp_hash = {
          cols: [:id, :group_id, :display_name, :repo_name, :local_dir],
          filter: [:oneof, :id, module_branches.map { |mb| mb[:repo_id] }]
        }
        ndx_repos = Model.get_objs(repo_mh, sp_hash).inject({}) { |h, repo| h.merge(repo.id => repo) }
        module_branches.each do |module_branch|
          module_branch[:repo] = ndx_repos[module_branch[:repo_id]]
        end
        module_branches
      end

      def augment_with_component_module!
        self.class.augment_with_component_modules!([self])
        self
      end

      private

      def self.augment_with_component_modules!(module_branches)
        return module_branches if module_branches.empty?
        component_module_mh = module_branches.first.model_handle(:component_module)
        sp_hash = {
          cols: [:id, :group_id, :display_name],
          filter: [:oneof, :id, module_branches.map { |mb| mb[:component_id] }]
        }
        ndx_component_modules = Model.get_objs(component_module_mh, sp_hash).inject({}) do |h, component_module| 
          h.merge(component_module.id => component_module) 
        end
        module_branches.each do |module_branch|
          module_branch[:component_module] = ndx_component_modules[module_branch[:component_id]]
        end
        module_branches
      end


      # assumed that all raw_module_rows agree on all except repo_remote
      def self.aggregate_by_remote_namespace(raw_module_rows, opts = {})
        ret = nil
        # raw_module_rows should have morea than 1 row and should agree on all fields aside from :repo_remote
        if raw_module_rows.empty?
          fail Error.new('Unexepected that raw_module_rows is empty')
        end
        namespace = (opts[:filter] || {})[:remote_namespace]
        
        repo_remotes = raw_module_rows.map do |e|
          if repo_remote = e.delete(:repo_remote)
            if namespace.nil? || namespace == repo_remote[:repo_namespace]
              repo_remote
            end
          end
        end.compact
        # if filtering by namespace (tested by namespace is non-null) and nothing matched then return ret (which is nil)
        # TODO: should we return nil when just repo_remotes.empty?
        if namespace && repo_remotes.empty?
          return ret
        end
        
        raw_module_rows.first.merge(repo_remotes: repo_remotes)
      end

      def raise_unexpected_nil(what)
        fail(Error, "Unexpected that #{what} is nil")
      end

    end
  end
end
