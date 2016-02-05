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
module XYZ
  class RepoController < Controller
    def rest__delete
      repo_id = ret_non_null_request_params(:repo_id)
      Repo.delete(id_handle(repo_id))
      rest_ok_response
    end

    # TODO: using maybe just temporarily to import when adding files
    def rest__synchronize_target_repo
      # TODO: check that refrershing all appropriate  implemnations by just using project_project_id is not null test
      repo_id = ret_non_null_request_params(:repo_id)
      repo = create_object_from_id(repo_id)
      sp_hash = {
        cols: [:id, :group_id, :display_name, :local_dir],
        filter: [:and, [:eq, :repo_id, repo_id], [:neq, :project_project_id, nil]]
      }
      impls = Model.get_objs(model_handle(:implementation), sp_hash)
      fail Error.new('Expecting to just find one matching implementation') unless impls.size == 1
      impl = impls.first
      impl.create_file_assets_from_dir_els()
      impl.add_contained_files_and_push_to_repo()
      rest_ok_response
    end
  end
end