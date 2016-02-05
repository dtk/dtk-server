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
  class ServiceModule; class AssemblyExport
    r8_require('v2')
    class V3 < V2
      private

      def add_component_link_to_cmp(component_in_ret, out_parsed_port)
        ret = {}
        if component_in_ret.is_a?(Hash)
          ret = component_in_ret
          component_links = ret.values.first[:component_links] ||= {}
        else # it will be a string
          component_links = {}
          ret = { component_in_ret => { component_links: component_links } }
        end
        output_target = component_link_output_target(out_parsed_port)
        link_def_ref = out_parsed_port[:link_def_ref]
        if existing_links = component_links[link_def_ref]
          if existing_links.is_a?(Array)
            existing_links << output_target
          else #existing_links.kind_of?(String)
            # turn into array with existing plus new element
            component_links[link_def_ref] = [component_links[link_def_ref], output_target]
          end
        else
          component_links.merge!(link_def_ref => output_target)
        end
        ret
      end

      def component_link_output_target(parsed_port)
        node_name = parsed_port[:node_name]
        ret = parsed_port[:component_name]
        ret = "#{node_name}#{Seperators[:node_component]}#{ret}" unless node_name.eql?('assembly_wide')
        if title = parsed_port[:title]
          ret << "#{Seperators[:title_before]}#{title}#{Seperators[:title_after]}"
        end
        ret
      end

    end
  end; end
end