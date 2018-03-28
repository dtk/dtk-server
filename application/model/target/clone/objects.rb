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
  class Target
    class Clone
      class Objects
        def initialize(clone_copy_output)
          @clone_copy_output = clone_copy_output
        end

        def nodes
          children_objects(:node, cols: [:display_name, :external_ref, :type])
        end

        def ports
          object_form(:port)
        end

        def port_links
          object_form(:port_link)
        end

        def link_defs
          object_form(:link_def)
        end

        # opts can have keys"
        #   :hash_form
        def components(opts = {})
          opts[:hash_form] ? hash_form_array(:component) : object_form(:component)
        end

        def task_templates
          children_objects(:task_template, cols: [:task_action])
        end

        protected

        attr_reader :clone_copy_output

        private

        CLONE_COPY_LEVEL = {
          node: 1,
          port_link: 1,
          task_templates: 1,
          component: 2,
          port: 2,
          link_def: 3
        }
        
        def hash_form_array(type)
          self.clone_copy_output.children_hash_form(level(type), type)
        end

        def object_form(type)
          hash_form_array(type).map do |info| 
            info[:id_handle].create_object.merge(info[:obj_info]) 
          end
        end

        # opts can have keys:
        #   :cols
        def children_objects(type, opts = {})
          self.clone_copy_output.children_objects(level(type), type, opts)
        end

        def level(type)
          CLONE_COPY_LEVEL[type] || fail(Error, "Invalid type '#{type}'")
        end

      end
    end
  end
end

