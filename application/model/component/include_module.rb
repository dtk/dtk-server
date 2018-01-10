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
module DTK; class Component
  class IncludeModule < Model
    def self.common_columns
      [:id, :group_id, :display_name, :version_constraint]
    end

    def module_name
      get_field?(:display_name)
    end

    # For all components in component_idhs, this method returns its implementation plus
    # does recursive anaysis to follow the components includes to find other components that must be included also
    def self.get_matching_implementations(assembly_instance, component_idhs)
      # TODO: check that  Component.get_implementations is consistent with what ModuleRefs::Lock returns
      # with respect to namespace resolution
      ret =  Component.get_implementations(component_idhs)
      include_modules = get_include_modules(component_idhs)
      return ret if include_modules.empty?()

      unless assembly_instance
        Log.error('Unexpected that assembly_instance is nil in IncludeModule.get_matching_implementations; not putting in includes')
        return ret
      end

      # Add to the impls in ret the ones gotten by following the include moulde links
      # using ndx_ret to get rid of duplicates
      # includes are indexed on components, so at first level get component modules, but then can only see what component modules
      # are includes using ModuleRefs::Lock
      ndx_ret = ret.inject({}) { |h, impl| h.merge(impl.id => impl) }
      module_names = include_modules.map(&:module_name)

      fail "TODO: DTK-3395: this wil be removed as part of DTK-3395"
      # included_impls = ModuleRefs::Lock.get_implementations(assembly_instance, module_names) 
      # remove dups from included_impls
      # included_impls.inject(ndx_ret) { |h, impl| h.merge(impl.id => impl) }.values
    end

    private

    def self.get_include_modules(component_idhs)
      Component.get_include_modules(component_idhs, cols: common_columns())
    end
  end
end; end
