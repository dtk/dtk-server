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
  # Class Mixins
  #
  module ModuleClassMixin
    include ModuleCommonMixin::Remote::Class
    include ModuleCommonMixin::Create::Class
    include ModuleCommonMixin::GetBranchClassMixin

    def component_type
      Log.info_pp(['#TODO: ModuleBranch::Location: deprecate for this being in ModuleBranch::Location local params', caller[0..4]])
      case module_type
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
      model_name
    end

    def check_valid_id(model_handle, id)
      check_valid_id_default(model_handle, id)
    end

    def name_to_id(model_handle, name_or_full_module_name, namespace = nil)
      namespace_x, name = Namespace.full_module_name_parts?(name_or_full_module_name)
      unless namespace ||= namespace_x
        fail ErrorUsage.new('Cannot find namespace!')
      end

      namespace_obj = Namespace.find_by_name(model_handle.createMH(:namespace), namespace)

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
      mh = idhs.first.createMH
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
        unsorted_ret.reject! { |r| r[:module_branch] && r[:module_branch][:version] != ModuleBranch.version_field_default }
      end

      if opts[:remove_assembly_branches]
        unsorted_ret.reject! { |r| r[:module_branch] && r[:module_branch].assembly_module_version? }
      end

      # if namespace provided with list command filter before aggregating details
      unsorted_ret = filter_by_namespace(unsorted_ret, namespace) if namespace

      filter_list!(unsorted_ret) if respond_to?(:filter_list!)
      unsorted_ret.each do |r|
        r.merge!(type: r.component_type) if r.respond_to?(:component_type)

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
        unsorted_ret = ModuleUtils::ListMethod.aggregate_detail(unsorted_ret, project_idh, model_type, opts_aggr)
      end

      unsorted_ret.sort { |a, b| a[:display_name] <=> b[:display_name] }
    end

    # opts can have keys
    #  :cols
    #  :filter
    def get_all(project_idh, opts = {})
      filter = [:eq, :project_project_id, project_idh.get_id]
      if opts[:filter]
        filter = [:and, filter, opts[:filter]]
      end
      sp_hash = {
        cols: add_default_cols?(opts[:cols]),
        filter: filter
      }
      mh = project_idh.createMH(model_type)
      get_objs(mh, sp_hash)
    end
    
    def module_exists(project, namespace, name, version = 'master')
      namespace_obj = Namespace.find_or_create(project.model_handle.createMH(:namespace), namespace)

      opts = Opts.new(filter: [:and, [:eq, :namespace_id, namespace_obj.id], [:eq, :display_name, name]], project_idh: project.id_handle, detail_to_include: [:remotes, :versions])
      cols = [:id, :display_name, :namespace_id, :namespace, :module_branches_with_repos]
      unsorted_ret = get_all(project.id_handle, cols: cols, filter: opts[:filter])

      if selected_module = unsorted_ret.find{ |mod| mod[:module_branch][:verion] == version }
        return selected_module[:id]
      end

      return nil
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
        delete_instance(repo_user.id_handle)
      end
    end

    def module_repo_info(repo, module_and_branch_info, opts = {})
      info = module_and_branch_info #for succinctness
      branch_obj = info[:module_branch_idh].create_object
      ModuleRepoInfo.new(repo, info[:module_name], info[:module_idh], branch_obj, opts)
    end

    def pp_module_ref(module_name, version = nil)
      version ? "#{module_name} (#{version})" : module_name
    end

    def module_exists?(project_idh, module_name, module_namespace)
      namespace_obj = Namespace.find_or_create(project_idh.createMH(:namespace), module_namespace)

      sp_hash = {
        cols: [:id, :group_id, :display_name],
        filter: [:and,
                 [:eq, :project_project_id, project_idh.get_id],
                 [:eq, :display_name, module_name],
                 [:eq, :namespace_id, namespace_obj.id]
                   ]
      }

      get_obj(project_idh.createMH(model_type), sp_hash)
    end

    private

    # can be overwritten
    # TODO: ModuleBranch::Location: deprecate
    def module_specific_type(_config_agent_type)
      module_type 
    end

    def get_all_repos(mh)
      get_objs(mh, cols: [:repos]).inject({}) do |h, r|
        repo = r[:repo]
        h[repo[:id]] ||= repo
        h
      end.values
    end
  end
end
