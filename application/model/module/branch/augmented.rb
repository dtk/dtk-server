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

      REQUIRED_PARAMS = [:module_name, :namespace] 
      def self.create(module_branch, params = {})
        missing_params =  REQUIRED_PARAMS - params.keys
        fail Error, "Missing the following keys: #{missing_params.join(', ')}" unless missing_params.empty?
        module_branch.merge(params).create_as_subclass_object(self)
      end

      def self.create_from_module_branch(module_branch)
        sp_hash = {
          cols: [:display_name, :augmented_branch_info, :namespace]
        }
        module_branch_id = module_branch.id
        aug_module_obj = module_branch.get_module.get_objs(sp_hash).find { |r| r[:module_branch][:id] == module_branch_id }
        aug_module_params = {
          module_name: aug_module_obj.display_name, 
          repo: aug_module_obj[:repo], 
          namespace: aug_module_obj[:namespace].display_name
        }
        create(aug_module_obj[:module_branch], aug_module_params)
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
          fail ErrorUsage.new("Module #{parent_module.pp_module_ref(version)} does not exist") unless opts[:donot_raise_error]
          return ret
        end

        # aggregate by remote_namespace, filtering by remote_namespace if remote_namespace is given
        unless aug_module_obj = aggregate_by_remote_namespace(module_rows, opts)
          fail ErrorUsage.new("The module (#{parent_module.pp_module_ref(version)}) is not tied to namespace '#{opts[:filter][:remote_namespace]}' on the repo manager")
        end

        aug_module_params = {
          module_name: aug_module_obj.display_name, 
          repo: aug_module_obj[:repo], 
          namespace: aug_module_obj[:namespace].display_name
        }
        aug_module_params.merge!(repo_remotes: aug_module_obj[:repo_remotes]) if opts[:include_repo_remotes]

        create(aug_module_obj[:module_branch], aug_module_params)
      end

      def get_matching_component_template?(component_name)
        component_type = Component.component_type_from_module_and_component(self.component_module_name, component_name)
        matches = get_component_templates.select { |component| component[:component_type] == component_type }
        fail Error "Unexpected that matches.size > 1" if matches.size > 1
        matches.first
      end

      def get_component_templates
        self.component_module.get_objs(cols: [:components]).select { |row| row[:module_branch].id == id }.map do |row|
          Component::Template.create_from_component(row[:component])
        end
      end

      def augment_with_component_module!
        self.class.augment_with_component_modules!([self])
      end

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
          component_module.get_field?(:display_name)
        end
      end
      def component_module_name
        component_module_name? || raise_unexpected_nil('component_module_name?') 
      end

      def component_module
        component_module? || raise_unexpected_nil('component_module?')
      end

      def module_name 
        self[:module_name] || raise_unexpected_nil('self[:module_name]')
      end

      def repo
        self[:repo] || raise_unexpected_nil('self[:repo]')
      end

      def current_sha
        update_current_sha_from_repo! unless self[:current_sha] 
        self[:current_sha] || raise_unexpected_nil('self[:current_sha]')
      end
      
      def branch_name
        self[:branch]  || raise_unexpected_nil('self[:branch]')
      end
      
      def namespace
        self[:namespace] || raise_unexpected_nil('self[:namespace]')
      end

      def frozen
        has_key?(:frozen) ? self[:frozen] : raise_unexpected_nil('self[:frozen]')
      end
      
      def implementation
        @implementation ||= get_implementation
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
        fail Error, "Unexpected that #{what} is nil"
      end

    end
  end
end
