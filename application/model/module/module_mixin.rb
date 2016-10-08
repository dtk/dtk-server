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
  #
  # Mixins agregation point, and refelected on service_module and component_module classes.
  #
  module ModuleMixin
    require_relative('module_mixin/get_basic_info')

    include ModuleCommonMixin::Remote::Instance
    include ModuleCommonMixin::Create::Instance
    include ModuleCommonMixin::Gitolite
    include ModuleCommonMixin::GetBranchMixin

    def ret_clone_update_info(version = nil)
      CloneUpdateInfo.new(self, version)
    end

    #
    # Get full module name
    #
    def full_module_name
      self.class.ndx_full_module_names([id_handle]).values.first
    end

    #
    # returns Array with: name, namespace, version
    #
    def get_basic_info(opts = Opts.new)
      sp_hash = {
        cols: [:id, :display_name, :version, :remote_repos],
        filter: [:eq, :id, id()]
      }

      rows = get_objs(sp_hash)
      GetBasicInfo.find_match(rows, opts) || fail(Error.new('Unexpected that there is no info associated with module'))
    end

    def list_versions(opts = {})
      local_versions  = []
      parsed_versions = []

      get_objs(cols: [:version_info]).each do |r|
        next if r[:module_branch].assembly_module_version?
        v = r[:module_branch].version()
        local_versions << (v.nil? ? 'base' : v)
      end

      base = local_versions.delete('base')
      local_versions.sort!()

      parsed_versions << base if opts[:include_base]
      parsed_versions << local_versions

      [{ versions: parsed_versions.flatten }]
    end

    def list_remote_versions(client_rsa_pub_key, opts = {})
      remote_versions = []
      parsed_versions = []
      module_name     = (default_linked_remote_repo||{})[:display_name]
      remote_versions = self.class.list_remotes(model_handle, client_rsa_pub_key, ret_versions_array: true).select { |r| r[:display_name] == module_name }.collect { |v_remote| v_remote[:versions] }.flatten.sort if module_name

      master = remote_versions.delete('master')
      parsed_versions << 'base' if opts[:include_base] && master
      parsed_versions << remote_versions

      [{ versions: parsed_versions.flatten }]
    end

    def list_remote_assemblies(project, remote_params, client_rsa_pub_key)
      remote = remote_params.create_remote(project)
      response = Repo::Remote.new(remote).list_remote_assemblies(client_rsa_pub_key)

      assemblies = response.map do |assembly|
        assembly_hash = assembly['assembly']||{}
        { display_name: assembly_hash['name'], description: assembly_hash['description'] }
      end

      assemblies
    end

    ##
    # Returns local and remote versions for module
    #

    def local_and_remote_versions(client_rsa_pub_key = nil, opts = {})
      Log.error('TODO: see if namespace treatment must be updated')
      module_name = nil
      remote_versions = []

      # get local versions list
      local_versions = get_objs(cols: [:version_info]).map do |r|
        v = r[:module_branch].version()
        v.nil? ? 'CURRENT' : v
      end
      # get all remote modules versions, and take only versions for current component module name
      info = self.class.info(model_handle(), id(), opts)
      module_name = info[:remote_repos].first[:repo_name].gsub(/\*/, '').strip() unless info[:remote_repos].empty?
      remote_versions = self.class.list_remotes(model_handle, client_rsa_pub_key).select { |r| r[:display_name] == module_name }.collect { |v_remote| ModuleBranch.version_from_version_field(v_remote[:versions]) }.map! { |v| v.nil? ? 'CURRENT' : v } if module_name

      local_hash  = { namespace: 'local', versions: local_versions.flatten }
      remote_hash = { namespace: 'remote', versions: remote_versions }

      versions = [local_hash]
      versions << remote_hash unless remote_versions.empty?

      versions
    end

    def get_linked_remote_repos(opts = {})
      (get_augmented_workspace_branch(opts.merge(include_repo_remotes: true)) || {})[:repo_remotes] || []
    end

    def default_linked_remote_repo
      get_linked_remote_repos(is_default: true).first
    end

    # this returns a DTK::ModuleDSLInfo object
    def update_model_from_clone_changes?(commit_sha, diffs_summary, version, opts = {})
      ret = ModuleDSLInfo.new
      # do pull and see if any changes need the model to be updated
      force         = opts[:force]
      generate_docs = opts[:generate_docs]

      module_branch = get_workspace_module_branch(version)
      pull_was_needed = module_branch.pull_repo_changes?(commit_sha, force)

      parse_needed = (opts[:force_parse] || generate_docs || !module_branch.dsl_parsed?())
      update_from_includes = opts[:update_from_includes]
      return ret unless pull_was_needed || parse_needed || update_from_includes

      # TODO: if need to generate docs, but not update the model can do something more efficient
      #       than code below, which class update to the model code even if no change to dsl files
      #       Instead would just want to call the parse code
      opts_update = Aux.hash_subset(opts, [:do_not_raise, :modification_type, :force_parse, :auto_update_module_refs, :dsl_parsed_false, :update_module_refs_from_file, :update_from_includes, :current_branch_sha, :service_instance_module, :task_action, :use_impl_id])
      opts_update.merge!(ret_parsed_dsl: ParsedDSL.create(self)) if generate_docs
      ret = update_model_from_clone_changes(commit_sha, diffs_summary, module_branch, version, opts_update)

      if generate_docs and ! ret[:dsl_parse_error]
        generate_and_persist_docs(module_branch, ret.parsed_dsl)
      end

      ret
    end

    def create_new_module_version(version, diffs_summary, opts = {})
      ret = ModuleDSLInfo.new
      # do pull and see if any changes need the model to be updated
      force         = opts[:force]
      generate_docs = opts[:generate_docs]

      # set frozen field in module branch object to true for new version
      opts.merge!(frozen: true)

      # create module branch for new version
      begin
        module_branch = self.create_new_version(nil, version, opts)
      rescue VersionExist => e
        return {version_exist: true} if opts[:do_not_raise_if_exist]
        fail e
      rescue Exception => e
        fail e
      end
      pull_was_needed = true

      parse_needed = (opts[:force_parse] || generate_docs || !module_branch.dsl_parsed?())
      update_from_includes = opts[:update_from_includes]

      opts_update = Aux.hash_subset(opts, [:do_not_raise, :modification_type, :force_parse, :auto_update_module_refs, :dsl_parsed_false, :update_module_refs_from_file, :update_from_includes, :current_branch_sha, :service_instance_module, :task_action])
      opts_update.merge!(ret_parsed_dsl: ParsedDSL.create(self)) if generate_docs
      ret = update_model_from_clone_changes(nil, diffs_summary, module_branch, version, opts_update)

      if generate_docs and ! ret[:dsl_parse_error]
        generate_and_persist_docs(module_branch, ret.parsed_dsl)
      end

      ret
    end

    def get_project
      # caching
      return self[:project] if self[:project]
      update_object!(:project_project_id, :display_name) #including :display_name is opportunistic
      if project_id = self[:project_project_id]
        self[:project] = id_handle(model_name: :project, id: project_id).create_object()
      end
    end

    # TODO: ModuleBranch::Location : need to paramterize this on branch
    # raises exception if more repos found
    def get_repo
      repos = get_repos()

      unless repos.size == 1
        fail Error.new('unexpected that number of matching repos is not equal to 1')
      end

      repos.first()
    end

    def get_repos
      get_objs_uniq(:repos)
    end

    def get_implementations
      get_objs_uniq(:implementations)
    end

    def module_type
      self.class.module_type()
    end

    def module_name
      get_field?(:display_name)
    end

    def module_namespace
      get_field?(:namespace)[:display_name]
    end

    def module_namespace_obj
      get_field?(:namespace)
    end

    def pp_module_name(version = nil)
      self.class.pp_module_name(module_name(), version)
    end

    def pp_module_branch_name(module_branch)
      module_branch.update_object!(:version)
      version = (module_branch.has_default_version?() ? nil : module_branch[:version])
      self.class.pp_module_name(module_name(), version)
    end

    # TODO: think want to deprecate these since dsl_parsed is on module branch, not module
    def set_dsl_parsed!(boolean_val)
      update(dsl_parsed: boolean_val)
    end
    def dsl_parsed?
      get_field?(:dsl_parsed)
    end

    # assumed that all raw_module_rows agree on all except repo_remote
    def aggregate_by_remote_namespace(raw_module_rows, opts = {})
      ret = nil
      # raw_module_rows should have morea than 1 row and should agree on all fields aside from :repo_remote
      if raw_module_rows.empty?()
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

    private

    ##
    # Generate documentations based on template files in docs/ folder. After than perisist that generated documentation to git repo
    #
    def generate_and_persist_docs(module_branch, parsed_dsl)
      doc_generator = DocGenerator.new(module_branch, parsed_dsl).generate!(raise_error_on_missing_var: false)
      file_path__content_array = doc_generator.file_path__content_array
      return if file_path__content_array.empty?

      # add and commit these files
      final_doc_paths = doc_generator.file_paths
      commit_msg = "Adding generated document files: #{final_doc_paths.join(', ')}"
      RepoManager.add_files(module_branch, file_path__content_array, commit_msg: commit_msg)

      # finally we push these changes
      RepoManager.push_changes(module_branch)
    end
  end
end
