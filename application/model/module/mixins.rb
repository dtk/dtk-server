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
r8_nested_require('mixins', 'remote')
r8_nested_require('mixins', 'create')
r8_nested_require('mixins', 'gitolite')
r8_nested_require('mixins', 'get_branch')
r8_nested_require('utils', 'list_method')

#
# Mixins agregation point, and refelected on service_module and component_module classes.
#

module DTK
  #
  # Instance Mixins
  #
  module ModuleMixin
    include ModuleMixins::Remote::Instance
    include ModuleMixins::Create::Instance
    include ModuleMixins::Gitolite
    include ModuleMixins::GetBranchMixin

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
      unless match = GetBasicInfo.find_match(rows, opts)
        fail Error.new('Unexpected that there is no info associated with module')
      end
      match
    end

    module GetBasicInfo
      #
      # returns Array with: name, namespace, version
      #
      def self.find_match(rows, opts)
        remote_namespace = opts[:remote_namespace]
        match =
          if rows.size == 1
            rows.first
          elsif rows.size > 1
            rows.find { |r| remote_namespace_match?(r, remote_namespace) }
          end
        if match
          name_namespace_version(match)
        end
      end

      private

      def self.name_namespace_version(row)
        [row[:display_name], remote_namespace(row), (row[:module_branch] || {})[:version]]
      end

      def self.remote_namespace_match?(row, remote_namespace = nil)
        if remote_namespace
          remote_namespace(row) == remote_namespace
        else
          repo_remote(row)[:is_default]
        end
      end

      def self.repo_remote(row)
        row[:repo_remote] || {}
      end
      def self.remote_namespace(row)
        repo_remote(row)[:repo_namespace]
      end
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
    def get_repo!
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
      RepoManager.add_files(module_branch, file_path__content_array, commit_msg)
      
      # finally we push these changes
      RepoManager.push_changes(module_branch)
    end
  end

  #
  # Class Mixins
  #
  module ModuleClassMixin
    include ModuleMixins::Remote::Class
    include ModuleMixins::Create::Class
    include ModuleMixins::GetBranchClassMixin

    def component_type
      Log.info_pp(['#TODO: ModuleBranch::Location: deprecate for this being in ModuleBranch::Location local params', caller[0..4]])
      case module_type()
       when :service_module
        :service_module
       when :component_module
        :puppet #TODO: hard wired
       when :test_module
        :puppet #TODO: hard wired
       when :node_module
        :puppet #TODO: hard wired
      end
    end

    def module_type
      model_name()
    end

    def check_valid_id(model_handle, id)
      check_valid_id_default(model_handle, id)
    end

    def name_to_id(model_handle, name_or_full_module_name, namespace = nil)
      namespace_x, name = Namespace.full_module_name_parts?(name_or_full_module_name)
      unless namespace ||= namespace_x
        fail ErrorUsage.new('Cannot find namespace!')
      end

      unless namespace_obj = Namespace.find_by_name(model_handle.createMH(:namespace), namespace)
        fail ErrorUsage.new("Namespace '#{namespace}' does not exist!")
      end

      sp_hash = {
       cols: [:id],
       filter: [:and, [:eq, :namespace_id, namespace_obj.id], [:eq, :display_name, name]]
      }
      name_to_id_helper(model_handle, name, sp_hash)
    end

    # arguments are module idhs
    def ndx_full_module_names(idhs)
      ret = {}
      return ret if idhs.empty?
      sp_hash =  {
        cols: [:id, :group_id, :display_name, :namespace],
        filter: [:oneof, :id, idhs.map(&:get_id)]
      }
      mh = idhs.first.createMH()
      get_objs(mh, sp_hash).inject({}) do |h, row|
        namespace   = row[:namespace]
        module_name = row[:display_name]
        full_module_name = (namespace ? Namespace.join_namespace(namespace[:display_name], module_name) : module_name)
        h.merge(row[:id] => full_module_name)
      end
    end

    def info(target_mh, id, opts = {})
      opts = Opts.new(filter: [:eq, :id, id], project_idh: opts[:project_idh], detail_to_include: [:remotes])
      list(opts).first
    end

=begin
TODO: remove after incorporating in info above displaying of remotes; this was removed because it processed dsl_parsed incorrectly
    def info(target_mh, id, opts = {})
      project_idh  = opts[:project_idh]
      namespaces = []

      sp_hash = {
        cols: [:id, :group_id, :display_name, :remote_repos],
        filter: [:eq, :id, id]
      }

      response = get_objs(target_mh, sp_hash.merge(opts))

      # if there are no remotes just get component info
      if response.empty?
        sp_hash = {
          cols: [:id, :group_id, :display_name],
          filter: [:eq, :id, id]
        }

        response = get_objs(target_mh, sp_hash.merge(opts))
      else
        # we sort in ascending order, last remote is default one
        # TODO: need to make more sophisticated so we dont end up comparing a '' to a date
        response.sort { |a, b| ((b[:repo_remote] || {})[:created_at] || '') <=> ((a[:repo_remote] || {})[:created_at] || '') }

        # we switch to ascending order
        response.each_with_index do |e, i|
          display_name = (e[:repo_remote] || {})[:display_name]
          prefix = (i == 0 ? '*' : ' ')
          namespaces << { repo_name: "#{prefix} #{display_name}" }
        end
      end

      filter_list!(response) if respond_to?(:filter_list!)
      response.each { |r| r.merge!(type: r.component_type()) if r.respond_to?(:component_type) }
      response = ModuleUtils::ListMethod.aggregate_detail(response, project_idh, model_type(), Opts.new(include_versions: true))

      ret = response.first || {}
      ret[:versions] = 'CURRENT' unless ret[:versions]
      ret.delete_if { |k, _v| [:repo, :module_branch, :repo_remote].include?(k) }
      # [Haris] Due to join condition with module.branch we can have situations where we have many versions
      # of module with same remote branch, with 'uniq' we iron that out

      ret.merge!(remote_repos: namespaces.uniq) if namespaces
      ret
    end
=end

    def list(opts = opts.new)
      diff               = opts[:diff]
      namespace          = opts[:namespace]
      filter             = opts[:filter]
      project_idh        = opts.required(:project_idh)
      remote_repo_base   = opts[:remote_repo_base]
      include_remotes    = opts.array(:detail_to_include).include?(:remotes)
      include_versions   = opts.array(:detail_to_include).include?(:versions)
      include_any_detail = ((include_remotes || include_versions) ? true : nil)

      cols = [:id, :display_name, :namespace_id, :namespace, include_any_detail && :module_branches_with_repos].compact
      unsorted_ret = get_all(project_idh, cols: cols, filter: filter)
      unless include_versions
        # prune all but the base module branch
        unsorted_ret.reject! { |r| r[:module_branch] && r[:module_branch][:version] != ModuleBranch.version_field_default() }
      end

      # if namespace provided with list command filter before aggregating details
      unsorted_ret = filter_by_namespace(unsorted_ret, namespace) if namespace

      filter_list!(unsorted_ret) if respond_to?(:filter_list!)
      unsorted_ret.each do |r|
        r.merge!(type: r.component_type()) if r.respond_to?(:component_type)

        if r[:namespace]
          r[:display_name] = Namespace.join_namespace(r[:namespace][:display_name], r[:display_name])
        end

        r[:dsl_parsed] = r[:module_branch][:dsl_parsed] if r[:module_branch]
      end

      if include_any_detail
        opts_aggr = Opts.new(
          include_remotes: include_remotes,
          include_versions: include_versions,
          remote_repo_base: remote_repo_base,
          diff: diff
        )
        unsorted_ret = ModuleUtils::ListMethod.aggregate_detail(unsorted_ret, project_idh, model_type(), opts_aggr)
      end

      unsorted_ret.sort { |a, b| a[:display_name] <=> b[:display_name] }
    end

    # opts can have keys
    #  :cols
    #  :filter
    def get_all(project_idh, opts = {})
      filter = [:eq, :project_project_id, project_idh.get_id()]
      if opts[:filter]
        filter = [:and, filter, opts[:filter]]
      end
      sp_hash = {
        cols: add_default_cols?(opts[:cols]),
        filter: filter
      }
      mh = project_idh.createMH(model_type())
      get_objs(mh, sp_hash)
    end

    def filter_by_namespace(object_list, namespace)
      return object_list if namespace.nil? || namespace.strip.empty?

      object_list.select do |el|
        if el[:namespace]
          # these are local modules and have namespace object
          namespace.eql?(el[:namespace][:display_name])
        else
          el[:display_name].match(/#{namespace}\//)
        end
      end
    end

    def add_user_direct_access(model_handle, rsa_pub_key, username = nil)
      repo_user, match = RepoUser.add_repo_user?(:client, model_handle.createMH(:repo_user), { public: rsa_pub_key }, username)
      model_name = model_handle[:model_name]

      repo_user.update_direct_access(model_name, true)
      repos = get_all_repos(model_handle)
      unless repos.empty?
        repo_names = repos.map { |r| r[:repo_name] }
        RepoManager.set_user_rights_in_repos(repo_user[:username], repo_names, DefaultAccessRights)

        repos.map { |repo| RepoUserAcl.update_model(repo, repo_user, DefaultAccessRights) }
      end
      [match, repo_user]
    end

    DefaultAccessRights = 'RW+'

    def remove_user_direct_access(model_handle, username)
      repo_user = RepoUser.get_matching_repo_user(model_handle.createMH(:repo_user), username: username)
      fail ErrorUsage.new("User '#{username}' does not exist") unless repo_user
      # return unless repo_user

      model_name = model_handle[:model_name]
      return unless repo_user.has_direct_access?(model_name)

      # confusing since it is going to gitolite
      RepoManager.delete_user(username)

      repos = get_all_repos(model_handle)
      unless repos.empty?
        repo_names = repos.map { |r| r[:repo_name] }
        RepoManager.remove_user_rights_in_repos(username, repo_names)
        # repo user acls deleted by foriegn key cascade
      end

      if repo_user.any_direct_access_except?(model_name)
        repo_user.update_direct_access(model_name, false)
      else
        delete_instance(repo_user.id_handle())
      end
    end

    def module_repo_info(repo, module_and_branch_info, opts = {})
      info = module_and_branch_info #for succinctness
      branch_obj = info[:module_branch_idh].create_object()
      ModuleRepoInfo.new(repo, info[:module_name], info[:module_idh], branch_obj, opts)
    end

    def pp_module_name(module_name, version = nil)
      version ? "#{module_name} (#{version})" : module_name
    end

    def module_exists?(project_idh, module_name, module_namespace)
      namespace_obj = Namespace.find_or_create(project_idh.createMH(:namespace), module_namespace)

      sp_hash = {
        cols: [:id, :group_id, :display_name],
        filter: [:and,
                 [:eq, :project_project_id, project_idh.get_id()],
                 [:eq, :display_name, module_name],
                 [:eq, :namespace_id, namespace_obj.id()]
                   ]
      }

      get_obj(project_idh.createMH(model_name()), sp_hash)
    end

    private

    # can be overwritten
    # TODO: ModuleBranch::Location: deprecate
    def module_specific_type(_config_agent_type)
      module_type()
    end

    def get_all_repos(mh)
      get_objs(mh, cols: [:repos]).inject({}) do |h, r|
        repo = r[:repo]
        h[repo[:id]] ||= repo
        h
      end.values
    end
  end

  class ModuleRepoInfo < Hash
    def initialize(repo, module_name, module_idh, branch_obj, opts = {})
      super()
      repo_name = repo.get_field?(:repo_name)
      module_namespace =  opts[:module_namespace]
      full_module_name = module_namespace ? Namespace.join_namespace(module_namespace, module_name) : nil
      hash = {
        repo_id: repo[:id],
        repo_name: repo_name,
        module_id: module_idh.get_id(),
        module_name: module_name,
        module_namespace: module_namespace,
        full_module_name: full_module_name,
        module_branch_idh: branch_obj.id_handle(),
        repo_url: RepoManager.repo_url(repo_name),
        workspace_branch: branch_obj.get_field?(:branch),
        branch_head_sha: RepoManager.branch_head_sha(branch_obj),
        frozen: branch_obj[:frozen]
      }

      if version = opts[:version]
        hash.merge!(version: version)
        if assembly_name = version.respond_to?(:assembly_name) && version.assembly_name()
          hash.merge!(assembly_name: assembly_name)
        end
      end

      hash.merge!(merge_warning_message: opts[:merge_warning_message]) if opts[:merge_warning_message]
      replace(hash)
    end
  end

  class CloneUpdateInfo < ModuleRepoInfo
    def initialize(module_obj, version = nil)
      aug_branch = module_obj.get_augmented_workspace_branch(filter: { version: version })
      opts = { version: version, module_namespace: module_obj.module_namespace() }
      opts.merge!(merge_warning_message: module_obj[:merge_warning_message]) if module_obj[:merge_warning_message]
      super(aug_branch[:repo], aug_branch[:module_name], module_obj.id_handle(), aug_branch, opts)
      self[:commit_sha] = aug_branch[:current_sha]
    end
  end
end