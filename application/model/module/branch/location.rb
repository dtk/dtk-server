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
      r8_nested_require('location', 'params')
      # above needed before below
      r8_nested_require('location', 'local')
      r8_nested_require('location', 'remote')
      # above needed before below
      r8_nested_require('location', 'server')
      r8_nested_require('location', 'client')

      attr_reader :local, :remote

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