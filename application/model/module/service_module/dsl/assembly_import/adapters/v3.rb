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
module DTK; class ServiceModule
  class AssemblyImport
    r8_require('v2')
    class V3 < V2
      # returns Array with each element being Hash with keys :parsed_component_link, :base_cmp_name
      def self.parse_component_links(assembly_hash, opts = {})
        ret = []
        (assembly_hash['nodes'] || {}).each_pair do |input_node_name, node_hash|
          components = (node_hash || {})['components'] || []
          components = [components] unless components.is_a?(Array)
          components.each do |base_cmp|
            if base_cmp.is_a?(Hash)
              base_cmp_name = base_cmp.keys.first
              component_links = base_cmp.values.first['component_links'] || {}
              ParsingError.raise_error_if_not(component_links, Hash, type: 'component link', context: base_cmp)
              component_links.each_pair do |link_def_type, targets|
                Array(targets).each do |target|
                  component_link_hash = { link_def_type => target }
                  parsed_component_link = PortRef.parse_component_link(input_node_name, base_cmp_name, component_link_hash, opts)
                  ret << { parsed_component_link: parsed_component_link, base_cmp_name: base_cmp_name }
                end
              end
            end
          end
        end
        ret
      end
    end
  end
end; end