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
  class Repo < Model
    require_relative('repo/with_branch')
    require_relative('repo/diff')
    require_relative('repo/diffs')
    require_relative('repo/remote')
    require_relative('repo/connection_to_remote')
    extend ConnectionToRemoteClassMixin
    include ConnectionToRemoteMixin

    def self.common_columns
      [:id, :display_name, :repo_name, :local_dir]
    end

    ###virtual columns
    def base_dir
      self[:local_dir].gsub(/\/[^\/]+$/, '')
    end
    ####
    def self.get_all_repo_names(model_handle)
      get_objs(model_handle, cols: [:repo_name]).map { |r| r[:repo_name] }
    end

    def get_acesss_rights(repo_user_idh)
      sp_hash = {
        cols: [:id, :group_id, :access_rights, :repo_usel_id, :repo_id],
        filter: [:and, [:eq, :repo_id, id()], [:eq, :repo_user_id, repo_user_idh.get_id()]]
      }
      Model.get_obj(model_handle(:repo_user_acl), sp_hash)
    end

    def default_remote!
      RepoRemote.default_remote!(self.model_handle(:repo_remote), self.id)
    end

    def self.delete(repo_idh)
      repo = repo_idh.create_object()
      RepoManager.delete_repo(repo)
      Model.delete_instance(repo_idh)
    end
  end
end
