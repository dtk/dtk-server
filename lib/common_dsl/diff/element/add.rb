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
  class CommonDSL::Diff
    class Element
      class Add < self
        attr_reader :parse_object
        # opts can have keys
        #  :parse_object
        #  :service_instance
        def initialize(qualified_key, opts = {})
          fail Error, "Unexpected that opts[:parse_object] is nil" unless opts[:parse_object]
          fail Error, "Unexpected that opts[:service_instance] is nil" unless opts[:service_instance]

          super(qualified_key, service_instance: opts[:service_instance])
          @parse_object = opts[:parse_object]
        end

        def serialize(serialized_hash)
          serialized_hash.serialize_add_element(self)
        end

        private
        # opts can have keys:
        #   :service_instance_branch (required)
        #   :component_module_refs
        def component_module_refs(opts = {})
          unless @component_module_refs ||= opts[:component_module_refs]
            service_instance_branch = opts[:service_instance_branch] || fail(Error, "Unexpected that opts[:service_instance_branch] is nil")
            @component_module_refs ||= ModuleRefs.get_component_module_refs(service_instance_branch)
          end
          @component_module_refs
        end        
        
      end
    end
  end
end
