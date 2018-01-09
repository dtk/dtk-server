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
  class ModuleRefSha
    class Info
      attr_reader :namespace, :module_name, :version, :level, :children_module_names, :external_ref
      attr_accessor :implementation, :module_branch
      def initialize(namespace, module_name, level, extra_fields = {})
        @namespace             = namespace
        @module_name           = module_name
        @level                 = level
        @version               = extra_fields[:version]
        @children_module_names = extra_fields[:children_module_names] || []
        @implementation        = extra_fields[:implementation]
        @module_branch         = extra_fields[:module_branch]
        @external_ref          = extra_fields[:external_ref]
      end
      
      def self.create_from_hash(mh, info_hash)
        impl = info_hash[:implementation]
        mb = info_hash[:module_branch]
        extra_fields = {
          children_module_names: info_hash[:children_module_names],
          implementation: object_form(mh.createMH(:implementation), info_hash[:implementation]),
          module_branch: object_form(mh.createMH(:module_branch), info_hash[:module_branch])
        }
        if external_ref = info_hash[:external_ref]
          extra_fields.merge!(external_ref: external_ref)
        end
        new(info_hash[:namespace], info_hash[:module_name], info_hash[:level], extra_fields)
      end
      
      def hash_form
        ret = {
          namespace: self.namespace,
          module_name: self.module_name,
          level: self.level,
          children_module_names: self.children_module_names
        }
        ret.merge!(implementation: self.implementation) if implementation
        ret.merge!(module_branch: module_branch) if module_branch
        ret.merge!(external_ref: external_ref) if external_ref
        ret
      end
      
      def children_and_this_module_names
        [self.module_name] + self.children_module_names
      end
      
      private
      
      def self.object_form(mh, hash)
        ret = nil
        return ret unless hash
        unless id = hash[:id]
          Log.error_pp(['Unexpected that hash does not have :id field', hash])
          return ret
        end
        mh.createIDH(id: id).create_object().merge(hash)
      end
    end
  end
end
