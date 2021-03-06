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
  class Repo
    class WithBranch < self
      # opts can have keys:
      #  :delete_if_exists - Boolean (default: false)
      #  :push_created_branch  - Boolean (default: false)
      #  :donot_create_master_branch - Boolean (default: false)
      #  :create_branch  - branch to create (f non nil)
      #  :add_remote_files_info - subclass of DTK::RepoManager::AddRemoteFilesInfo
      def self.create_actual_repo(project_idh, local, opts = {})
        repo_user_acls = RepoUser.authorized_users_acls(project_idh)
        repo_mh        = project_idh.createMH(:repo)
        ret            = create_obj?(repo_mh, local)
        repo_idh       = repo_mh.createIDH(id: ret.id)
        RepoUserAcl.modify_model(repo_idh, repo_user_acls)
        RepoManager.create_workspace_repo(ret, repo_user_acls, opts)
        ret
      end

      def self.create_obj?(model_handle, local)
        repo_name          = local.repo_name
        repo_display_name  = local.repo_display_name

        repo_obj = obj_exists?(model_handle, repo_display_name) || create_obj(model_handle, repo_name, repo_display_name)
        set_branch_name!(repo_obj, local.branch_name)
      end

      def initial_sync_with_remote(remote, remote_repo_info)
        remote_url    = remote.repo_url
        remote_ref    = remote.remote_ref
        remote_branch = remote.branch_name

        raise_error_if_version_not_on_remote(remote_repo_info, remote_branch)

        # returns commit_sha
        RepoManager.initial_sync_with_remote_repo(branch_name, get_field?(:repo_name), remote_ref, remote_url, remote_branch)
      end

      def delete_local_brach_only(branch_name)
        RepoManager.delete_local_brach(branch_name, get_field?(:repo_name), branch_name)
      end

      private

      def self.obj_exists?(model_handle, repo_display_name)
        sp_hash = {
          cols: common_columns,
          filter: [:eq, :display_name, repo_display_name]
        }
        get_obj(model_handle, sp_hash)
      end

      # Returns a Repo object
      def self.create_obj(model_handle, repo_name, repo_display_name)
        repo_hash = {
          ref: repo_display_name,
          display_name: repo_display_name,
          repo_name: repo_name,
          local_dir: "#{R8::Config[:repo][:base_directory]}/#{repo_name}" #TODO: should this be set by RepoManager instead
        }
        repo_idh = create_from_row(model_handle, repo_hash)
        repo_idh.create_object(model_name: :repo_with_branch).merge(repo_hash)
      end

      def raise_error_if_version_not_on_remote(remote_repo_info, remote_branch)
        if remote_branches = remote_repo_info[:branches]
          fail ErrorUsage.new("Cannot find selected version on remote repo #{remote_repo_info[:full_name] || ''}") unless remote_branches.include?(remote_branch)
        end
      end

      def self.set_branch_name!(repo_obj, branch_name)
        repo_obj.merge!(branch_name: branch_name)
      end

      def branch_name
        self[:branch_name] || fail(Error, "Unexpected that self[:branch_name] is null for: #{inspect}")
      end

      def self.get_objs(mh, sp_hash, opts = {})
        model_handle = (mh[:model_name] == :repo_with_branch ? mh.createMH(:repo) : mh)
        super(model_handle, sp_hash, { subclass_model_name: :repo_with_branch }.merge(opts))
      end
    end
  end
end
