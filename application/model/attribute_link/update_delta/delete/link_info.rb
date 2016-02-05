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
module DTK; class AttributeLink; class UpdateDelta
  class Delete
    class LinkInfo
      attr_reader :input_attribute, :deleted_links, :other_links
      def initialize(input_attribute)
        @input_attribute = input_attribute
        @deleted_links = []
        @other_links = []
      end
      
      def add_other_link!(link)
        @other_links << link unless match?(@other_links, link)
      end
      
      def add_deleted_link!(link)
        @deleted_links << link unless match?(@deleted_links, link)
      end

      private
      
      def match?(links, link)
        attribute_link_id = link[:attribute_link_id]
        links.find { |l| l[:attribute_link_id] == attribute_link_id }
      end

    end
  end
end; end; end