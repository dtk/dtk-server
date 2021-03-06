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
  module ComponentTitle
    def self.print_form_with_title(component_name, title)
      "#{component_name}[#{title}]"
    end

    # this is for field display_name
    def self.display_name_with_title(component_type, title)
      "#{component_type}[#{title}]"
    end
    def self.display_name_with_title?(component_type, title = nil)
      title ? display_name_with_title(component_type, title) : component_type
    end

    def self.ref_with_title(component_type, title)
      sanitized_title = title.gsub(/\//, '__')
      "#{component_type}--#{sanitized_title}"
    end

    def self.parse_component_user_friendly_name(user_friendly_name, opts = {})
      node_name = component_type = title = nil
      cmp_display_name = Component.display_name_from_user_friendly_name(user_friendly_name)
      cmp_node_part, title = parse_component_display_name(cmp_display_name, opts)
    end

    # parse_component_display_name
    # if opts has :node_prefix, returns [node_name,component_type,title]
    # else returns [component_type,title]
    # if ilegal form, nil will be returned
    # in all cases title could be nil
    def self.parse_component_display_name(cmp_display_name, opts = {})
      node_name = component_type = title = nil
      cmp_node_part = nil
      if cmp_display_name =~ ComponentTitleRegex
        cmp_node_part = Regexp.last_match(1)
        title = Regexp.last_match(2)
      else
        cmp_node_part = cmp_display_name
      end

      ret = nil
      unless opts[:node_prefix]
        component_type = cmp_node_part
        if opts[:return_version]
          component_type, version = validate_version(component_type)
          ret = [component_type, title, version]
        else
          ret = [component_type, title]
        end
      else
        if cmp_node_part =~ SplitNodeComponentType
          node_name = Regexp.last_match(1)
          component_type = Regexp.last_match(2)
        else
          component_type = cmp_node_part
        end
        ret = [node_name, component_type, title]
      end

      if component_type =~ LegalComponentType
        ret
      end
    end


    LegalComponentType = /^[^\/]+$/ #TODO: make more restricting
    SplitNodeComponentType = /(^[^\/]+)\/([^\/]+$)/

    def self.parse_title?(cmp_display_name)
      if cmp_display_name =~ ComponentTitleRegex
        Regexp.last_match(2)
      end
    end
    ComponentTitleRegex = /(^.+)\[(.+)\]$/

    # component can be a hash or object
    def self.title?(component)
      return nil unless component #convienence so dont have to check argument being passed is nil
      display_name = component[:display_name] || (component.is_a?(Component) && component.get_field?(:display_name))
      unless display_name
        fail Error.new('Parameter (component) should have :display_name field')
      end
      component_type, title = parse_component_display_name(display_name)
      title
    end

  end
end
