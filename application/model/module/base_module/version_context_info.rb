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
  class BaseModule < Model
    module VersionContextInfo
      # returns a hash with keys: :repo,:branch,:implementation, :sha (optional)
      def self.get_in_hash_form(components, assembly_instance)
        impls = Component::IncludeModule.get_matching_implementations(assembly_instance, components.map(&:id_handle))
        sha_info = get_sha_indexed_by_impl(components)
        impls.map { |impl| hash_form(impl, sha_info[impl[:id]]) }
      end

      private

      def self.hash_form(impl, sha = nil)
        hash = impl.hash_form_subset(:id, :repo, :branch, { module_name: :implementation })
        sha ? hash.merge(sha: sha) : hash
      end

      def self.get_sha_indexed_by_impl(components)
        ret = {}
        return ret if components.empty?
        sp_hash = {
          cols: [:id, :group_id, :display_name, :locked_sha, :implementation_id],
          filter: [:oneof, :id, components.map(&:id)]
        }
        Model.get_objs(components.first.model_handle(), sp_hash).each do |r|
          if sha = r[:locked_sha]
            ret.merge!(r[:implementation_id] => sha)
          end
        end
        ret
      end
    end
  end
end