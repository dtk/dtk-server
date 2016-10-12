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
  class RepoManager::Git 
    class ManageGitServer
      module ClassMixin
        def method_missing(name, *args, &block)
          if git_server_class.respond_to?(name)
            git_server_class.send(name, *args, &block)
          else
            super
          end
        end
        
        def respond_to?(name)
          !!(git_server_class.respond_to?(name) || super)
        end
        
        # TODO: should use method missing for below
        def create_server_repo(repo_obj, repo_user_acls, opts = {})
          git_server_class.create_server_repo(repo_obj, repo_user_acls, opts)
        end
        
        def delete_all_server_repos
          git_server_class.delete_all_server_repos
        end
        
        def delete_server_repo(repo)
          git_server_class.delete_server_repo(repo)
        end
        
        private
        
        def git_server_class
          return @git_server_class if @git_server_class
          adapter_name = ((R8::Config[:repo] || {})[:git] || {})[:server_type]
          fail Error.new('No repo git server adapter specified') unless adapter_name
          @git_server_class = DynamicLoader.load_and_return_adapter_class('manage_git_server', adapter_name, base_class: RepoManager::Git, subclass_adapter_name: true)
          @git_server_class.set_git_class(self)
        end
      end
    end
  end
end
