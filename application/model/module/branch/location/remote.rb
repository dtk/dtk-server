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
module DTK; class ModuleBranch
  class Location
    class RemoteParams < Params
      # keys: :module_type,:module_name,:remote_repo_base,:namespace,:version?
      def remote_repo_base
        self[:remote_repo_base]
      end

      class DTKNCatalog < self
        def create_remote(project)
          Remote::DTKNCatalog.new(project, self)
        end

        private

        def legal_keys
          [:module_type, :module_name, :remote_repo_base, :namespace, :version?]
        end
      end

      class TenantCatalog < self
        def create_remote(project)
          Remote::TenantCatalog.new(project, self)
        end

        private

        def legal_keys
          [:module_type, :module_name, :remote_repo_base, :namespace?, :version?]
        end
      end
    end

    class Remote
      def self.includes?(obj)
        obj.is_a?(DTKNCatalog) || obj.is_a?(TenantCatalog)
      end

      module RemoteMixin
        attr_reader :project
        def initialize(project, remote_params)
          super(remote_params)
          @project = project
        end

        def branch_name
          @branch_name ||= ret_branch_name()
        end

        def remote_ref
          @remote_ref ||= ret_remote_ref()
        end

        def repo_url
          @repo_url ||= ret_repo_url()
        end

        def set_repo_name!(remote_repo_name)
          if @repo_name
            fail Error.new('Not expected that @repo_name is non nil')
          end
          @repo_name = remote_repo_name
          self
        end

        def repo_name
          if @repo_name.nil?
            fail Error.new('Not expected that @repo_name is nil')
          end
          @repo_name
        end
      end
      r8_nested_require('remote', 'dtkn_catalog')
      r8_nested_require('remote', 'tenant_catalog')
    end
  end
end; end