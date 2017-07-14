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
  class PortLink
    class ComponentInfo
      require_relative('component_info/endpoint')

      def initialize(local_endpoint, remote_endpoint)
        @local_endpoint  = local_endpoint
        @remote_endpoint = remote_endpoint
      end
      private :initialize

      attr_reader :local_endpoint, :remote_endpoint

      def self.get?(parent_idh, port_link_hash)
        local_endpoint, remote_endpoint = get_endpoints?(parent_idh, port_link_hash)
        if local_endpoint and remote_endpoint
          new(local_endpoint, remote_endpoint)
        end
      end
      
      def matching_link_def_link?
        return nil unless self.local_endpoint.link_type ==  self.remote_endpoint.link_type

        match = self.local_endpoint.aug_ports.find do |aug_port|
          possible_link = aug_port[:link_def_link] || {}
          if possible_link[:remote_component_type] == remote_component_type
            case possible_link[:type]
            when 'internal'
              self.components_on_same_node? or self.component_on_remote_node?
            when 'external'
              ! self.components_on_same_node?
            else 
              Log.Error("Unexpected possible_link[:type] '#{possible_link[:type]}'")
              nil
            end
          end
        end
        match && match[:link_def_link].merge!(local_component_type: self.local_component_type)
      end

      def local_component 
        @local_component ||= self.local_endpoint.component
      end

      def remote_component 
        # remote_component treated differently than local_component because we need to get more info about it
        @remote_component ||= get_remote_component
      end

      def component_on_remote_node?
        if @component_on_remote_node.nil?
          ret = false
          if self.local_component.get_field?(:assembly_id) != self.remote_component.get_field?(:assembly_id)
            ret = true if self.just_internal_link? and self.local_endpoint.is_assembly_wide_node? and ! self.remote_endpoint.is_assembly_wide_node?
          end
          @component_on_remote_node = ret
        else
          @component_on_remote_node
        end
      end

      protected
      
      def local_component_type
        @local_component_type ||= self.local_component[:component_type]
      end
      
      def remote_component_type
        @remote_component_type ||= self.remote_component[:component_type]
      end

      def components_on_same_node?
        if @components_on_same_node.nil?
          @components_on_same_node = (self.local_endpoint.node_id == self.remote_endpoint.node_id)
        else
          @components_on_same_node
        end
      end

      def just_internal_link?
        self.link_def[:has_internal_link] and ! self.link_def[:has_external_link] 
      end      
      
      def link_def
        @link_def ||= self.local_endpoint.link_def
      end
      
      private
      
      # returns [local_endpoint, remote_endpoint] or nil
      def self.get_endpoints?(parent_idh, port_link_hash)
        sp_hash = {
          cols: [:id, :group_id, :display_name, :component_type, :direction, :link_type, :link_def_info, :node_node_id],
          filter: [:oneof, :id, [port_link_hash[:input_id], port_link_hash[:output_id]]]
        }
        ports_with_link_def_info = Port.get_objs(parent_idh.createMH(:port), sp_hash)
        local_aug_ports = ports_with_link_def_info.select { |r| (r[:link_def] || {})[:local_or_remote] == 'local' }
        return nil if local_aug_ports.empty?
        component_id = local_aug_ports.first.id
      
        remote_aug_ports = ports_with_link_def_info.select { |r| r.id != component_id }
        if remote_aug_ports.empty?
          fail Error, 'Unexpected result that a remote port cannot be found'
        end
        [Endpoint.new(local_aug_ports), Endpoint.new(remote_aug_ports)]
      end
      
      def get_remote_component
        # get remote component
        remote_aug_port = self.remote_endpoint.aug_ports.first
        sp_hash = {
          cols: [:id, :group_id, :display_name, :node_node_id, :component_type, :implementation_id, :extended_base],
          filter: [:and, Component::Instance.filter(remote_aug_port.component_type, remote_aug_port.title?),
                   [:eq, :node_node_id, remote_aug_port[:node_node_id]]
                  ]
        }
        Model.get_obj(self.local_component.model_handle, sp_hash)
      end

    end
  end
end
