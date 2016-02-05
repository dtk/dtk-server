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
  class ModuleRef
    class Lock < Model
      r8_nested_require('lock', 'info')
      r8_nested_require('lock', 'persist')

      def self.common_columns
        [:id, :display_name, :group_id, :module_name, :info, :locked_branch_sha]
      end

      attr_accessor :info
      def initialize(*args, &block)
        super
        @info = nil
      end

      def locked_branch_sha
        self[:locked_branch_sha]
      end

      def locked_branch_sha=(sha)
        self[:locked_branch_sha] = sha
      end

      def module_name
        (@info && @info.module_name) || (Log.error_pp(['Unexpected that no module name', self]); nil)
      end

      def self.create_from_element(assembly_instance, info)
        ret = create_stub(assembly_instance.model_handle(:module_ref_lock))
        ret.info = info
        ret
      end

      def self.create_or_update(module_refs_lock)
        Persist.create_or_update(module_refs_lock)
      end

      def self.get(assembly_instance)
        Persist.get(assembly_instance).map(&:reify)
      end

      def reify
        info_hash = self[:info]
        @info = info_hash && Info.create_from_hash(model_handle, info_hash)
        self
      end

    end
  end
end