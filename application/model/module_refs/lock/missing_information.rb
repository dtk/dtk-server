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
# TODO: thing we wil be able to deprecate this
module DTK; class ModuleRefs
  class Lock
    class MissingInformation < self
      def initialize(assembly_instance, missing, complete, types, opts)
        super(assembly_instance)
        @missing = missing
        @complete = complete
        @types = types
        @opts = opts
      end

      # types will be subset of [:locked_dependencies, :locked_branch_shas]
      # opts can have
      #  :with_module_branches - Boolean
      def self.missing_information?(module_refs_lock, types, opts = {})
        # partition into rows that are missing info and ones that are not
        missing = {}
        complete = {}
        module_refs_lock.each_pair do |module_name, module_ref_lock|
          if el_missing_information?(module_ref_lock, types, opts)
            missing[module_name] = module_ref_lock
          else
            complete[module_name] = module_ref_lock
          end
        end
        unless missing.empty?
          new(module_refs_lock.assembly_instance, missing, complete, types, opts)
        end
      end

      private

      def self.el_missing_information?(module_ref_lock, types, opts = {})
        if types.include?(:locked_dependencies)
          unless info = module_ref_lock.info
            return true
          end
          if opts[:with_module_branches]
            unless info.module_branch
              return true
            end
          end
        end
        if types.include?(:locked_branch_shas)
          unless module_ref_lock.locked_branch_sha
            return true
          end
        end
        false
      end
    end
  end
end; end