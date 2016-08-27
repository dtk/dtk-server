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
  module CommonDSL::Generate
    class ContentInput
      class ServiceInstance < ContentInput::Hash
        def initialize(service_instance, module_branch)
          super()
          @service_instance = service_instance
          @module_branch    = module_branch
        end

        def generate_content_input!
          assembly_instance = @service_instance.assembly_instance
          set(:DSLVersion, @module_branch.dsl_version)
          set(:Name, assembly_instance.display_name) 
          set(:Assembly, Assembly.generate_content_input(assembly_instance))
          self
        end

        ### For diffs
        def diff?(service_instance)
          # DSLVersion and Name will be the same
          # service_instance has assembly attributes at same level as DSLVersion and Name
          diff = req(:Assembly).diff?(service_instance)
# TODO: debug
File.open('/tmp/raw', 'w') {|f| PP.pp(diff, f) }
if collated_diff = diff && diff.collate
  #  File.open('/tmp/collated', 'w') {|f| PP.pp(collated_diff, f) }
  pp collated_diff
end
          diff
        end
      end
    end
  end
end
