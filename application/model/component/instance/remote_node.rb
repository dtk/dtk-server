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
  class Component::Instance
    class RemoteNode
      def initialize(component_instances, assembly_instance)
        @component_instances = component_instances
        @assembly_instance   = assembly_instance
        # these ger dynamically updated
        @remote_node_ndx                      = {}
        @ndx_linked_assembly_wide_components  = {}
      end
      private :initialize
      
      # Returns hash where key isa compoennt instatnce and value is a remote node
      def self.ndx_component_instances_on_remote_nodes(component_instances, assembly_instance)
        return {} if component_instances.empty? 
        new(component_instances, assembly_instance).ndx_component_instances_on_remote_nodes
      end
      def ndx_component_instances_on_remote_nodes
        compute_ndx_info! # computes self.remote_node_ndx.empty? and self.ndx_linked_assembly_wide_components
        return {} if self.remote_node_ndx.empty? #short cut since if no direct remotes then there will be no indirect remotes
        add_indirects_to_remote_node_ndx!
      end
      
      protected
      
      attr_reader :component_instances, :assembly_instance, :remote_node_ndx, :ndx_linked_assembly_wide_components
      
      def port_links
        @port_links ||= Component::Instance.get_port_links(self.component_idhs, input: true)
      end
      
      def port_link_component_info
        @port_link_component_info ||= self.port_links.map{ |port_link| PortLink::ComponentInfo.get?(self.assembly_instance.id_handle, port_link) }.compact
      end
      
      def component_idhs
        @component_idhs ||= self.component_instances.map(&:id_handle)
      end
      
      private

      def compute_ndx_info!
        self.port_link_component_info.each do |component_info|
          local_endpoint = component_info.local_endpoint
          component_id   = local_endpoint.component.id
          
          if component_info.component_directly_on_remote_node?
            remote_node = component_info.remote_endpoint.node.update_obj!(:display_name, :group_id, :external_ref, :ordered_component_ids, :type)
            @remote_node_ndx[component_id] = remote_node
          elsif linked_assembly_wide_components?(component_info)
            @ndx_linked_assembly_wide_components[component_id] = component_info.remote_component.id
          end
        end
      end

      def linked_assembly_wide_components?(component_info)
        component_info.just_internal_link? and
          component_info.local_endpoint.is_assembly_wide_node? and
          component_info.remote_endpoint.is_assembly_wide_node?
      end
      
      def add_indirects_to_remote_node_ndx!
        self.ndx_linked_assembly_wide_components.keys.each do |component_id|
          @remote_node_ndx[component_id] ||= transitive_closure_remote_node?(component_id)
        end
        self.remote_node_ndx
      end

      def transitive_closure_remote_node?(component_id)
        if remote_node = self.remote_node_ndx[component_id]
          remote_node
        elsif linked_component_id = self.ndx_linked_assembly_wide_components[component_id]
          transitive_closure_remote_node?(linked_component_id)
        else
          nil
        end
      end

    end
  end
end
