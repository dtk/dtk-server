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
module DTK; module CommandAndControlAdapter
  class Ec2
    class CreateNode
      r8_nested_require('create_node', 'create_options')

      # TODO: can remove these mixins and put directly in this file      
      #using include on class mixins because this class is instance based, not class based
      include NodeStateClassMixin
      include AddressManagementClassMixin

      attr_reader :reified_node, :node, :external_ref
      def initialize(base_node, node, reified_target)
        @external_ref = node[:external_ref] || {} # TODO: wil eventually remove 
        @base_node    = base_node
        @node         = node
        @reified_node = Reified::Node.create_with_reified_target(node, reified_target, external_ref: @external_ref)
      end
      private :initialize
      
      def self.run(task_action)
        single_run_responses = create_node_object_per_node(task_action).map(&:run)
        aggregate_responses(single_run_responses)
      end
      
      def run
        run_aux()
      end
      
      private
      
      def create_ec2_instance
        response = nil
        begin
          create_options = CreateOptions.new(self)
          Log.info_pp(create_options: Aux.hash_subset(create_options, AttributesForLogInfo))
          response = conn.server_create(create_options)
          response[:status] ||= 'succeeded'
        rescue => e
          # append region to error message
          region = @reified_node.region
          e.message << ". Region: '#{region}'." if region
          Log.error_pp([e, e.backtrace[0..10]])
          return { status: 'failed', error_object: e, type: 'user_error' }
        end
        response
      end
      
      AttributesForLogInfo = [:image_id, :flavor_id, :security_group_ids, :groups, :tags, :key_name, :subnet_id]
      
      NodeCols = [:os_type, :external_ref, :hostname_external_ref, :display_name, :assembly_id]
      def self.create_node_object_per_node(task_action)
        nodes = task_action.nodes(cols: NodeCols)
        reified_target = Reified::Target.new(task_action.target_service)
        base_node = task_action.base_node()
        nodes.map { |node| new(base_node, node, reified_target) }
      end
      
      def self.aggregate_responses(single_run_responses)
        if single_run_responses.size == 1
          single_run_responses.first
        else
          #TODO: just finds first error now
          if first_error = single_run_responses.find { |r| r[:status] == 'failed' }
            first_error
          else
            #assuming all ok responses are the same
            single_run_responses.first
          end
        end
      end
      
      def run_aux
        create_node = true
        if instance_id = @external_ref[:instance_id]
          # handle case where node is terminated and need to recreate
          if get_node_status(instance_id) == :terminated
            Log.info("node instance id #{instance_id} has been terminated; creating new node")
          else
            create_node = false
            Log.info("node already created with instance id #{instance_id}; waiting for it to be available")
          end
        end
        
        if create_node
          generate_client_token?()
          
          response = create_ec2_instance()
          if response[:status] == 'failed'
            return response
          end
          
          instance_id = response[:id]
          state = response[:state]
          
          update_params = {
            base_node: @base_node,
            iaas_specfic_params: { size: @reified_node.instance_type },
            external_ref: @external_ref
          }
          Ec2.update_node_from_create_node!(node, 'ec2_instance', instance_id, update_params)
        end
        
        process_addresses__first_boot?(@node)
        
        Ec2.return_status_ok.merge(node: {external_ref: @external_ref})
      end
      
      def generate_client_token?
        unless @external_ref[:client_token]
          # generate client token
          client_token = @external_ref[:client_token] = Ec2::ClientToken.generate()
          Log.info("Generated client token '#{client_token}' for node '#{node_print_form}'")
          updated_external_ref = @external_ref.merge(client_token: client_token)
          update_node!(external_ref: updated_external_ref)
        end
      end
      
      def update_node!(node_update_hash)
        Ec2.update_node!(@node, node_update_hash)
        if er = node_update_hash[:external_ref]
          @external_ref = er
        end
        # TODO: no sure if '.merge!(node_update_hash)' needed
        @node.merge!(node_update_hash)
      end
      
      def get_node_status(instance_id)
        ret = nil
        begin
          target_aws_creds = Ec2.get_target_credentials(node)
          response = Ec2.conn(target_aws_creds).get_instance_status(instance_id)
          ret = response[:status] && response[:status].to_sym
        rescue => e
          Log.error_pp([e, e.backtrace[0..10]])
        end
        ret
        end

      def node_print_form
        Ec2.node_print_form(node)
      end
    end
  end
end; end
