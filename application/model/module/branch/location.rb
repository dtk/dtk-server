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
#
# Classes that encapsulate information for each module or moulde branch where is its location clone and where is its remotes
#
module DTK
  class ModuleBranch
    class Location
      require_relative('location/params')
      # above needed before below
      require_relative('location/local')
      require_relative('location/remote')
      # above needed before below
      require_relative('location/server')
      require_relative('location/client')

      attr_reader :local, :remote

      module Mixin
        def common_module_branch
          if get_field?(:type) == 'common_module'
            self
          else
            local = local_from_module_branch(module_type: :common_module)
            CommonModule.get_module_branch_from_local(local)
          end
        end

        private
        # opts can have keys
        #   :module_type
        def local_from_module_branch(opts = {})
          module_obj    = get_module
          namespace_obj = Namespace.get_obj(model_handle(:namespace), filter: [:eq, :id, module_obj.get_field?(:namespace_id)])
          project       =  module_obj.get_project

          params_hash = {
            module_type: opts[:module_type] || get_field?(:type),
            module_name: module_obj.display_name,
            version: get_field?(:version),
            namespace: namespace_obj.display_name
          }
          LocalParams::Server.new(params_hash).create_local(project)
        end
      end

      private

      def initialize(project, local_params = nil, remote_params = nil)
        if local_params
          @local = self.class::Local.new(project, local_params)
        end
        if remote_params
          @remote = self.class::Remote.new(project, remote_params)
        end
      end
    end
  end
end
