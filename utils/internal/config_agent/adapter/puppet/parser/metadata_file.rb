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
    module MetadataFile
      # used for parsing metadata.json when importing module from git (import-git)
      def self.parse?(impl_obj)
        ret = nil
        unless metadata_name = contains_metadata?(impl_obj)
          return ret
        end
        type = impl_obj[:type]

        json_content = RepoManager.get_file_content(metadata_name, implementation: impl_obj)

        content_hash = nil
        begin
          content_hash = Aux.convert_to_hash(json_content, :json)
        rescue => e
          return ret
        end
        if type = impl_obj[:type]
          content_hash.merge!(type: type)
        end
        content_hash.merge!(type: type) if type
        dependencies = (content_hash['dependencies'] || []).map { |hash_dep| ExternalDependency.new(hash_dep) }
        content = convert_to_internal_form(content_hash)
        { content: content, dependencies: dependencies }
      end

      private

      def self.contains_metadata?(impl_obj, _provider = nil)
        depth = 2
        RepoManager.ls_r(depth, { file_only: true }, impl_obj).find do |f|
          f.eql?('metadata.json') || f.eql?("#{Puppet.provider_folder()}/metadata.json")
        end
      end

      def self.convert_to_internal_form(content_hash)
        content_hash.inject({}) { |h, (k, v)| h.merge(k.to_sym => v) }
      end

      class ExternalDependency < Puppet::ExternalDependency
        def initialize(hash_content)
          super(hash_content['name'], hash_content['version_requirement'])
        end
      end
    end
  end; end
end; end