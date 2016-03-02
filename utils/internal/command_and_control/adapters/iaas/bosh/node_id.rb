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
  class CommandAndControl::IAAS::Bosh
    class NodeId
      attr_reader :deployment_name, :job, :index
      def initialize(node)
        @node = node
        # parsed_node_id needs to go after '@node = node'
        @deployment_name, @job, @index = parsed_node_id
      end

      def self.node_id(node)
        (node.get_field?(:external_ref) || {})[:instance_id]
      end

      def self.compute_node_id(node)
        # TODO: stub
        node_id_info = ['dtk', 'master', '0']
         node_id_info.join(Delimiter)
      end
      Delimiter = '--'

      private

      # returns [deployment_name, job, index]
      def parsed_node_id
        ret = node_id.split(Delimiter)
        pp [:node_id_split, ret]
        unless ret.size == 3 and ret[2] =~ /^[0-9]+$/
          fail Error.new("Node id '#{node_id}' has unexpected form")
        end
        ret
      end

      def node_id
        self.class.node_id(@node)
      end

    end
  end
end

