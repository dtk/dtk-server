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
module DTK; class Node
  class Filter
    def filter(nodes)
      filter_aux?(nodes)
    end

    def include?(node)
      !filter_aux?([node]).empty?
    end
    class NodeList < self
      def initialize(node_idhs)
        @node_ids = node_idhs.map(&:get_id)
      end

      def filter_aux?(nodes)
        nodes.select { |n| @node_ids.include?(n[:id]) }
      end
    end
  end
end; end