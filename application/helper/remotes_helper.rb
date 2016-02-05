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
module Ramaze::Helper
  module RemotesHelper
    def add_git_url(repo_remote_mh, repo_id, remote_url)
      remote_name = ::DTK::RepoRemote.remote_provider_name(remote_url)
      ::DTK::RepoRemote.create_git_remote(repo_remote_mh, repo_id, remote_name, remote_url)
    end

    def add_git_remote(module_obj)
      remote_name, remote_url = ret_non_null_request_params(:remote_name, :remote_url)
      repo_remote_mh   = module_obj.model_handle(:repo_remote)
      ::DTK::RepoRemote.create_git_remote(repo_remote_mh, module_obj.get_workspace_repo.id, remote_name, remote_url)
    end

    def remove_git_remote(module_obj)
      remote_name      = ret_non_null_request_params(:remote_name)
      repo_remote_mh   = module_obj.model_handle(:repo_remote)
      ::DTK::RepoRemote.delete_git_remote(repo_remote_mh, remote_name, module_obj.get_workspace_repo.id)
    end
  end
end