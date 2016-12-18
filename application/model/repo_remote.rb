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
  class RepoRemote < Model
    def print_form(opts = Opts.new)
      ret = self[:display_name] || '' #'' just to be safe
      ret = "#{remote_provider_name}://#{ret}" if opts[:provider_prefix]
      ret = "#{DefaultMarker}#{ret}" if opts[:is_default_namespace]
      ret
    end

    ALL_PROVIDERS    = ['github', 'bitbucket', 'dtkn']
    DEFAULT_PROVIDER = 'dtkn'
    DTKN_PROVIDER    = 'dtkn'

    #
    # remote location regex is used to detrmine if we are using special case of SSH git url e.g.
    # git@bitbucket.org:hkraji/stdlib.git/stdlib
    #
    # if so than we are pushing to URL but with location path provided after SSH git url (e.g. /stdlib)
    #
    REMOTE_LOCATION_REGEX = /(.*\.git)(\/.*)$/

    RemoteRepoBase = :dtknet
    DefaultMarker = '*'

    def self.get_git_remotes(module_obj)
      module_obj.get_linked_remote_repos.collect do |a|
        provider_name = a.remote_provider_name
        unless is_dtkn_provider_name?(provider_name)
          a.merge(
            url: a.git_remote_url,
            git_provider: provider_name,
            base_git_url: a.base_git_remote_url,
            base_git_location: a.base_git_remote_location
          )
        end
      end.compact
    end

    def self.repo_base
      RemoteRepoBase
    end

    def self.remote_provider_name(url_of_provider)
      ALL_PROVIDERS.each do |provider|
        return provider if url_of_provider.match(/(@|\/)#{provider}/)
      end

      DEFAULT_PROVIDER
    end

    def url_ssh_access
      RepoManagerClient.repo_url_ssh_access(get_field?(:repo_name))
    end

    def remote_provider_name
      RepoRemote.remote_provider_name(git_remote_url())
    end

    def git_remote_url
      get_field?(:repo_url) || self.url_ssh_access()
    end

    def base_git_remote_url
      url = git_remote_url()
      url = url.match(REMOTE_LOCATION_REGEX)[1] if is_there_remote_location?
      url
    end

    #
    # Based on git location - it sees if one is provided
    #
    def base_git_remote_location
      is_there_remote_location? ? git_remote_url().match(REMOTE_LOCATION_REGEX)[2] : nil
    end

    #
    # Checks if git remote location is specified
    #
    def is_there_remote_location?
      !!git_remote_url().match(REMOTE_LOCATION_REGEX)
    end

    def remote_ref
      if is_builtin_provider?
        Repo.remote_ref(RemoteRepoBase, get_field?(:repo_namespace))
      else
        remote_url = git_remote_url()

        if remote_url.start_with?('git')
          repo_name = remote_url.split(':').last().split('/').join('-').gsub(/\.git/, '')
        else
          repo_name = remote_url.split('/').last(2).join('-').gsub(/\.git/, '')
        end
        # example: hkraji-stdlib-github
        "#{repo_name}-#{remote_provider_name}"
      end
    end

    def self.create_git_remote(repo_remote_mh, repo_id, repo_name, repo_url, is_default = false)
      # check to see if repo remote exists
      repo_remotes = get_objs(repo_remote_mh, filter: [:and, [:eq, :display_name, repo_name], [:eq, :repo_id, repo_id]])

      unless repo_remotes.empty?
        fail ErrorUsage, "Remote identifier '#{repo_name}' already exists"
      end

      unless repo_url.match(/^git@.*:.*\.git\/?.*?$/)
        fail ErrorUsage, 'We are sorry, we only support SSH remotes - provided URL does not seem to be proper SSH url'
      end

      remote_repo_create_hash = {
        repo_name: repo_name,
        display_name: repo_name,
        ref: repo_name,
        repo_id: repo_id,
        repo_url: repo_url,
        is_default: is_default
      }

      create_from_row(repo_remote_mh, remote_repo_create_hash)
    end

    def self.delete_git_remote(repo_remote_mh, repo_name, repo_id)
      repo_remotes = get_objs(repo_remote_mh, filter: [:and, [:eq, :display_name, repo_name], [:eq, :repo_id, repo_id]])

      if repo_remotes.empty?
        fail ErrorUsage, "Remote '#{repo_name}' not found"
      end

      repo_remotes.each { |rr| rr.delete_instance(rr.id_handle) }
    end

    # opts can have keys:
    #   :set_as_default
    #   :set_as_default_if_first
    def self.create_repo_remote?(repo_remote_mh, module_name, repo_name, repo_namespace, repo_id, opts = {})
      unless get_remote_repo?(repo_remote_mh, repo_id, module_name, repo_namespace)
      create_repo_remote(repo_remote_mh, module_name, repo_name, repo_namespace, repo_id, opts)
      end
    end
    def self.create_repo_remote(repo_remote_mh, module_name, repo_name, repo_namespace, repo_id, opts = {})
      is_default =
        if opts[:set_as_default]
          true
        elsif opts[:set_as_default_if_first]
          get_matching_remote_repos(repo_remote_mh, repo_id, module_name).size == 0
        else
          false
        end

      remote_repo_create_hash = {
        repo_name: repo_name,
        display_name: "#{repo_namespace}/#{module_name}",
        repo_namespace: repo_namespace,
        repo_id: repo_id,
        ref: module_name,
        is_default: is_default
      }

      create_from_row(repo_remote_mh, remote_repo_create_hash)
    end

    def self.delete_repos(idh_list)
      delete_instances(idh_list)
    end

    def self.get_remote_repo?(repo_remote_mh, repo_id, module_name, repo_namespace)
      matches = get_matching_remote_repos(repo_remote_mh, repo_id, module_name, repo_namespace)
      if matches.size > 1
        Log.error("Unexpected to have multiple matches in get_remote_repo (#{matches.inspect})")
        # will pick first one
      end
      matches.first
    end

    def self.get_matching_remote_repos(repo_remote_mh, repo_id, module_name, repo_namespace = nil)
      sp_hash = {
        cols: [:id, :display_name, :repo_name],
        filter:           [:and,
                           [:eq, :repo_id, repo_id],
                           repo_namespace && [:eq, :repo_namespace, repo_namespace],
                           [:eq, :ref, module_name]
          ].compact
      }
      get_objs(repo_remote_mh, sp_hash)
    end

    def self.extract_module_name(repo_name)
      repo_name.split(/\-\-.{2}\-\-/).last
    end

    def remote_dtkn_location(project, module_type, module_name)
      remote_params = ModuleBranch::Location::RemoteParams::DTKNCatalog.new(
        module_type: module_type,
        module_name: module_name,
        namespace: get_field?(:repo_namespace),
        remote_repo_base: self.class.repo_base()
      )
      remote_params.create_remote(project).set_repo_name!(get_field?(:repo_name))
    end

    def self.default_from_module_branch?(module_branch)
      sp_hash = {
        cols: [:id, :group_id, :display_name, :repo_name, :repo_namespace, :is_default, :created_at],
        filter: [:eq, :repo_id, module_branch.get_field?(:repo_id)]
      }
      ret = get_objs(module_branch.model_handle(:repo_remote), sp_hash)
      1 == ret.size ? ret.first : default_repo_remote?(ret)
    end

    def self.default_repo_remote?(repo_remotes)
      # Making robust in case multiple ones marked default
      # and making robust for earlier bug where not dtkn modules can be marked default
      repo_remotes = (repo_remotes || []).reject { |r| !r.is_dtkn_provider? }

      pruned = repo_remotes.select { |r| r.get_field?(:is_default) }
      if pruned.empty?
        compute_default_remote_repo?(repo_remotes)
      elsif pruned.size == 1
        pruned.first
      else
        Log.error("Multiple default remotes found (#{pruned.map { |r| r[:display_name] }.join('')})")
        compute_default_remote_repo?(pruned)
      end
    end

    def self.default_remote!(repo_remote_mh, repo_id)
      repo_remote = get_obj(repo_remote_mh, filter: [:and, [:eq, :is_default, true], [:eq, :repo_id, repo_id]])
      fail ErrorUsage, 'Not able to find default remote for given repo!' unless repo_remote
      repo_remote
    end

    def is_builtin_provider?
      ALL_PROVIDERS.last.eql?(remote_provider_name())
    end

    def is_dtkn_provider?
      self.class.is_dtkn_provider_name?(remote_provider_name)
    end

    private

    def self.is_dtkn_provider_name?(provider_name)
      DTKN_PROVIDER.eql?(provider_name)
    end

    # TODO: deprecate once all data is migrated so :is_default is always explicitly marked
    def self.compute_default_remote_repo?(repo_remotes)
      unless (repo_remotes || []).empty?
        # TODO: enhance so that default is one that matches user's default namespace
        # set on augmented_module_branch[:repo] fields associated with the default namespace
        # we sort descending by created date
        # default is the one which is the oldest
        repo_remotes.each { |r| r.update_object!(:created_at) }
        default_repo_remote = repo_remotes.sort { |a, b| a[:created_at] <=> b[:created_at] }.first
        default_repo_remote
      end
    end
  end
end
