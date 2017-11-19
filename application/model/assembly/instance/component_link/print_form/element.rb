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
  class Assembly::Instance::ComponentLink::PrintForm
    module Element
      Info = Struct.new(:service_type, :base_ref, :dep_ref, :linked_cmp_id, :required, :description) 
      class Port
        def self.print_form_info(port, _opts = {})
          dep_ref = required = description = linked_cmp_id = nil
          
          base_ref     = port.display_name_print_form(hide_assembly_wide_node: true)
          service_type = port.link_def_name
          
          if link_def = port[:link_def]
            required = port[:required]
            description = port[:description]
          end
          Info.new(service_type, base_ref, dep_ref, linked_cmp_id, required, description) 
        end
      end
        
      class PortLink
        def initialize(port_link)
          @port_link = port_link
        end
        private :initialize

        def self.print_form_info(port_link)
          new(port_link).print_form_info
        end
        def print_form_info
          base_ref = dep_ref = description = required = nil
          # TODO: confusing that input/output on port link does not reflect what is logical input/output
          if self.port_link[:input_port][:direction] == 'input'
            base_ref = port_ref(:input)
            dep_ref  = port_ref(:output) 
          else
            base_ref = port_ref(:output)
            dep_ref  = port_ref(:input)
          end
          service_type = self.port_link[:input_port].link_def_name
          linked_cmp_id = self.port_link[:output_port][:component_id]
        
          Info.new(service_type, base_ref, dep_ref, linked_cmp_id, required, description) 
        end

        protected

        attr_reader :port_link

        private
      
        def port_ref(dir)
          to_aug = {
            node: index_port_link(dir, :node), 
            nested_component: index_port_link(dir, :component)
            
          }
          aug_port = index_port_link(dir, :port).merge(to_aug)
          aug_port.display_name_print_form(hide_assembly_wide_node: true)
        end

        def index_port_link(dir, type)
          self.port_link["#{dir}_#{type}".to_sym]
        end
        
      end
    end
  end
end
