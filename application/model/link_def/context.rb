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
  class LinkDef::Context
    require_relative('context/term_mappings')
    require_relative('context/node_mappings')
    require_relative('context/value')

    def self.create(link, link_defs_info)
      new(link, link_defs_info)
    end

    def local_component_template
      component_template(:local)
    end

    def remote_component_template
      component_template(:remote)
    end

    def initialize(link, link_defs_info)
      @link = link
      @component_mappings = component_mappings(link_defs_info)
      @node_mappings = NodeMappings.create_from_component_mappings(@component_mappings)

      @component_attr_index = {}
      # @term_mappings has element for each component, component attribute and node attribute
      @term_mappings = TermMappings.create_and_update_cmp_attr_index(
                          @node_mappings,
                          @component_attr_index,
                          @link.attribute_mappings,
                          @component_mappings)
      # these two function set all the component and attribute refs populated above
      @term_mappings.set_components!(@link, @component_mappings)
      @term_mappings.set_attribute_values!(@link, link_defs_info, @node_mappings)
    end
    private :initialize

    # returns array of LinkDef::Link::AttributeMapping::Augmented
    def aug_attr_mappings__clone_if_needed(opts = {})
      @link.attribute_mappings.inject([]) do |ret, am|
        ret + am.aug_attr_mappings__clone_if_needed(self, opts)
      end
    end

    def find_attribute_object?(term_index)
      @term_mappings.find_attribute_object?(term_index)
    end

    def remote_node
      @node_mappings.remote
    end

    def local_node
      @node_mappings.local
    end

    def temporal_order
      @link[:temporal_order]
    end

    def add_component_ref_and_value!(component_type, component)
      @term_mappings.add_ref_component!(component_type).set_component_value!(component)
      # update all attributes that ref this component
      cmp_id = component[:id]
      attrs_to_get = { cmp_id => { component: component, attribute_info: @component_attr_index[component_type] } }
      get_and_update_component_attributes!(attrs_to_get)
    end

    private

    def component_mappings(link_defs_info)
      local_cmp_type = @link[:local_component_type]
      local_cmp = get_component(local_cmp_type, link_defs_info)
      remote_cmp_type = @link[:remote_component_type]
      remote_cmp = get_component(remote_cmp_type, link_defs_info)
      { local: local_cmp, remote: remote_cmp }
    end

    def get_component(component_type, link_defs_info)
      match = link_defs_info.find { |r| component_type == r[:component][:component_type] }
      unless ret = match && match[:component]
        Log.error("component of type #{component_type} not found in  link_defs_info")
      end
      ret
    end

    def component_template(dir)
      Component::Instance.create_from_component(@component_mappings[dir]).get_component_template_parent
    end

  end
end
