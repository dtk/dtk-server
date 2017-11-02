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

#TODO: this might be deprecated#
module DTK
  class Assembly::Template
    class Stage
      class CustomNodeAttributes
        # opts can have keys:
        #  :node_size - example form  node_size - master=m3.xlarge,slave=m3.large or m3.xlarge
        #  :os_type - can be commas sepearetd list
        def initialize(assembly_instance, opts = {})
          @node_size = opts[:node_size]
          @os_type   = opts[:os_type]
          assembly_instance = assembly_instance
          @assembly_nodes   = assembly_instance.get_nodes.map(&:display_name)

        end
        
        def self.set_if_needed(assembly_instance, opts = {})
          new(assembly_instance, opts).set if opts[:node_size] or opts[:os_type]
        end

        def set
          return if self.assembly_nodes.empty?
          av_pairs = compute_attribute_value_pairs
          # TODO: does set_attributes opts need any more options?
          Attribute::Pattern::Assembly.set_attributes(self.assembly_instance, av_pairs, create: true) unless av_pairs.empty?
        end
        
        protected

        attr_reader :node_size, :os_type, :assembly_instance, :assembly_nodes

        private

        def compute_attribute_value_pairs
          av_pairs = []
          if node_sizes = self.node_size && self.node_size.split(',')
            added_nodes = []
            node_sizes.each{ |n_size| parse_and_add_attribute(av_pairs, n_size, added_nodes, 'instance_size') }
          end
          if os_types = self.os_type && self.os_type.split(',')
            added_nodes = []
            os_types.each{ |os_type| parse_and_add_attribute(av_pairs, os_type, added_nodes, 'os_identifier') }
          end
          av_pairs
        end
        
        def parse_and_add_attribute(av_pairs, param, added_nodes, attribute)
          if param.include?('=')
            n_name, n_size = param.split('=')
            added_nodes << n_name
            fail ErrorUsage, "Node '#{n_name}' specified in params does not exist in assembly template!" unless self.assembly_nodes.include?(n_name)
            av_pairs << {pattern: "#{n_name}/#{attribute}", value: "#{n_size}"}
          else
            self.assembly_nodes.each do |assembly_node|
              av_pairs << {pattern: "#{assembly_node}/#{attribute}", value: "#{param}"} unless added_nodes.include?(assembly_node)
            end
          end
        end
      end
    end
  end
end

