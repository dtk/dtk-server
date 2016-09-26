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
  module CommonDSL
    module ObjectLogic
      class Dependency < Generate::ContentInput::Hash
        def self.generate_content_input(assembly_instance, module_branch)
          new.generate_content_input!(assembly_instance, module_branch)
        end

        def generate_content_input!(assembly_instance, module_branch)
          set_id_handle(assembly_instance)

          components = ObjectLogic.new_content_input_hash
          dependencies = ObjectLogic.new_content_input_hash

          dependent_modules = assembly_instance.info_about(:modules, Opts.new(detail_to_include: [:version_info]))
          unless dependent_modules.empty?
            dependent_modules.each do |d_module|
              dependencies.merge!({ "#{d_module[:namespace_name]}/#{d_module[:display_name]}" => (d_module[:display_version] || 'master') })
            end
          end

          dependencies
        end

      end
    end
  end
end
