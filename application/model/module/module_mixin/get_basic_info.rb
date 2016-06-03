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
  module ModuleMixin
    module GetBasicInfo
      #
      # returns Array with: name, namespace, version
      #
      def self.find_match(rows, opts)
        remote_namespace = opts[:remote_namespace]
        match =
          if rows.size == 1
            rows.first
          elsif rows.size > 1
            rows.find { |r| remote_namespace_match?(r, remote_namespace) }
          end
        if match
          name_namespace_version(match)
        end
      end

      private

      def self.name_namespace_version(row)
        [row[:display_name], remote_namespace(row), (row[:module_branch] || {})[:version]]
      end

      def self.remote_namespace_match?(row, remote_namespace = nil)
        if remote_namespace
          remote_namespace(row) == remote_namespace
        else
          repo_remote(row)[:is_default]
        end
      end

      def self.repo_remote(row)
        row[:repo_remote] || {}
      end
      def self.remote_namespace(row)
        repo_remote(row)[:repo_namespace]
      end
    end
  end
end
