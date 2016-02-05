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
module DTK; class ServiceModule; class AssemblyExport
  module FoldIntoExisting
    class NodeBindingsSectionProc
      attr_reader :raw_array

      def initialize(raw_array = [])
        @raw_array = raw_array
      end

      def parse_and_order_node_bindings_hash(node_bindings_hash)
        parsed_content = parse_existing_and_remove_unused()
        order_node_bindings_hash(node_bindings_hash, parsed_content)
      end

      private

      def parse_existing_and_remove_unused
        ignore    = true
        new_array = []

        @raw_array.each do |el|
          name = el.strip

          if name.eql?('node_bindings:')
            ignore = false
            next
          elsif name.eql?('assembly:')
            ignore = true
          end

          unless ignore
            new_array << { name: name, content: el }
          end
        end

        new_array
      end

      def order_node_bindings_hash(node_bindings_hash, existing_node_bindings)
        assembly_hash_node_bindings = node_bindings_hash[:node_bindings]
        new_node_bindings = {}

        existing_node_bindings.each do |existing_nb|
          nb_name = existing_nb[:name].split(':').first
          new_nb = assembly_hash_node_bindings.delete(nb_name)

          if new_nb
            new_node_bindings.merge!(nb_name => new_nb)
          end
        end

        { :node_bindings => new_node_bindings.merge(assembly_hash_node_bindings) }
      end

    end
  end
end; end; end