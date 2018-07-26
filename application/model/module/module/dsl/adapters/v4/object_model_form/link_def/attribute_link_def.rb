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
module DTK; class ModuleDSL; class V4
  class ObjectModelForm; class LinkDef
    module AttributeLinkDef
      def self.convert_link_def_links(attributes, base_cmp)
        links_from_elements(attributes).inject([]) do |a, element|
          a + Choice::LinkDefLink::AttributeLinksFrom.convert(base_cmp, element.attribute_name, element.links_from_term)
        end
      end
      
      private
      
      LinksFromElement = Struct.new(:attribute_name, :attribute_info, :links_from_term)
      
      def self.links_from_elements(attributes)
        attributes.map do |attribute_name, info|
          if links_from = info['links_from']
            LinksFromElement.new(attribute_name, info, links_from)
          end
        end.compact
      end
      
    end
  end; end
end; end; end
