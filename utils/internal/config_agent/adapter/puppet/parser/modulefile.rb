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
module DTK; class ConfigAgent
  module Adapter; class Puppet
    module Modulefile
      # used for parsing Modulefile when importing module from git (import-git)
      def self.parse?(impl_obj)
        ret = nil
        unless modulefile_name = contains_modulefile?(impl_obj)
          return ret
        end

        content_hash = {}
        dependencies = []
        type = impl_obj[:type]

        content = RepoManager.get_file_content(modulefile_name, implementation: impl_obj)
        content.split("\n").each do |el|
          el.chomp!()
          next if (el.start_with?('#') || el.empty?)
          el.gsub!(/\'/, '')

          next unless match = el.match(/(\S+)\s(.+)/)
          key = match[1]
          value = match[2]
          if key.to_s.eql?('dependency')
            dependencies << ExternalDependency.new(value)
          end
          content_hash.merge!(key.to_sym => value.to_s)
        end

        content_hash.merge!(type: type) if type
        { content: content_hash, modulefile_name: modulefile_name, dependencies: dependencies }
      end

      private

      def self.contains_modulefile?(impl_obj)
       depth = 2
       RepoManager.ls_r(depth, { file_only: true }, impl_obj).find do |f|
          f.eql?('Modulefile') || f.eql?("#{Puppet.provider_folder()}/Modulefile")
        end
      end

      class ExternalDependency < Puppet::ExternalDependency
        def initialize(string_info)
          name, version = string_info.split(',')
          version.strip! if version
          super(name, version)
        end
      end
    end
  end; end
end; end