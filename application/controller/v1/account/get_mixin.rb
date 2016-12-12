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
  class V1::AccountController
    module GetMixin
      ### For all modules
      def list_ssh_keys
        username = ret_non_null_request_params(:username)
        model_handle = model_handle_with_private_group()
        datatype  = :account_ssh_keys
        # results = RepoUser.get_matching_repo_users(model_handle.createMH(:repo_user), { type: 'client' }, username, ['username'])
        repo_keys = CurrentSession.new.user_object.public_keys
        # we send current catalog user info in list ssh key table
        rest_ok_response repo_keys.each { |ssh_key_obj|  ssh_key_obj.merge!(:current_catalog_username => CurrentSession.catalog_username) if ssh_key_obj.has_repoman_direct_access? }, datatype: datatype
      end
    end
  end
end

