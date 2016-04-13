
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
# TODO: cleanup use of request_context
module DTK
  class CloudConnect
    class EC2 < self
      r8_nested_require('ec2', 'image_info_cache')

      WAIT_FOR_NODE = 10 # seconds

      def initialize(credentials_with_region)
        Log.info("Setting up AWS connection ...")
        @conn = Fog::Compute::AWS.new(credentials_with_region)
        @override_conns = OverrideConnectionOptions.inject({}) do |h, (k, conn_opts)|
          h.merge(k => Fog::Compute::AWS.new(credentials_with_region.merge(connection_options: conn_opts)))
        end
      end

      OverrideConnectionOptions = {
        # Setting retry_limit to 1, but using a mutex at a outer level to retry
        server_create: { read_timeout: 5, retry_limit: 1 }
      }

      def self.credentials_ok?(credentials_with_region)
        # picking arbitrray describe_ method to test
        ret = true
        begin 
          new(credentials_with_region).describe_availability_zones
        rescue
          ret = false
        end
        ret
      end

      def flavor_get(id)
        hash_form(conn.flavors.get(id))
      end

      def image_get?(id)
        ImageInfoCache.get_or_set(:image_get, conn, id, mutex: true) do
          begin
            if aws_image = conn.images.get(id)
              hash_form(aws_image)
            end
          rescue Exception => e
            unless defined?(PhusionPassenger)
              # DEBUG SNIPPET >>> REMOVE <<<
              require (RUBY_VERSION.match(/1\.8\..*/) ? 'ruby-debug' : 'debugger');Debugger.start; Debugger
              puts "debug mode"
            end
            # this is part of the code that I plan to use to troubleshoot images null pointer excpetion
            # that happens from time to time (non-deterministic)
            raise e
          end
        end
      end

      def servers_all
        conn.servers.all.map { |x| hash_form(x) }
      end

      def server_get(id)
        hash_form(wrap_servers_get(id))
      end

      def server_destroy(id)
        request_context do
          if server = wrap_servers_get(id)
            server.destroy
          else
            :server_does_not_exist
          end
        end
      end

      SERVER_CREATE_RETRIES = 5
      ServerCreateMutex = Mutex.new

      def server_create(options)
        # we add tag to identify it as slave service instance
        service_instance_ttl = R8::Config[:ec2][:service_instance][:ttl] || R8::Config[:idle][:up_time_hours]
        options[:tags] = options.fetch(:tags, Hash.new).merge('service.instance.ttl' => service_instance_ttl)

        # !!! set root disk to GP2 to override fog default; important performance change
        if options[:block_device_mapping].size > 1
          Log.error_pp(["TODO: check if correctly handling case with multiple block devices", options[:block_device_mapping]])
        end
        options[:block_device_mapping].first["Ebs.VolumeType"] = 'gp2'

        tries = SERVER_CREATE_RETRIES
        ret = nil
        while ret.nil? and tries > 0
          ServerCreateMutex.synchronize do
            begin
              Log.info("Start mutex server_create for #{options[:client_token]}; thread #{Aux.thread_id}")
              ret = hash_form(conn(:server_create).servers.create(options))
              Log.info("End mutex server_create for #{options[:client_token]}")
             rescue ::Excon::Errors::Timeout => e
              tries -= 1
              Log.info("Retrying server_create (retries_left = #{tries}) for #{options[:client_token]}") if tries > 0
            end
          end
        end
        ret || fail(ErrorUsage.new("Not able to create node; you can invoke again 'converge'"))
      end

      # TODO: cleanup
      StartRetries = 10

      def server_start(instance_id)
        (tries = StartRetries).times do
          begin
            ret = nil
            request_context do
              ret = hash_form(conn.start_instances(instance_id))
            end
            return ret
          rescue Fog::Compute::AWS::Error => e
            # expected error in case node is not stopped, wait try again
            if (e.message.include? 'IncorrectInstanceState')
              Log.debug "Node with instance ID '#{instance_id}' is not yet ready, waiting #{WAIT_FOR_NODE} seconds ..."
              sleep(WAIT_FOR_NODE)
              next
            end
            raise e
          end
        end # => 10 times loop end

        fail Error, "Node (Instance ID: '#{instance_id}') not ready after #{tries * WAIT_FOR_NODE} seconds."
      end


      def server_stop(instance_id)
        request_context do
          hash_form(conn.stop_instances(instance_id))
        end
      end

      # filter is attribute value pairs to match againts
      def security_groups(filter = {})
        ret = conn.security_groups.all.map { |aws_sg| hash_form(aws_sg) }
        ret.select { |hash_form_sg| filter_security_group?(hash_form_sg, filter) }
      end
      def security_group_by_id?(security_group_id, filter = {})
        if aws_sg = conn.security_groups.get_by_id(security_group_id)
          filter_security_group?(hash_form(aws_sg), filter)
        end
      end
      def security_group_by_name?(security_group_name, filter = {})
        if aws_sg = conn.security_groups.get(security_group_name)
          filter_security_group?(hash_form(aws_sg), filter)
        end
      end
      def filter_security_group?(hash_form_sg, filter)
        hash_form_sg unless filter.find { |k, v| hash_form_sg[k] != v }
      end
      private :filter_security_group?

      def describe_availability_zones
        conn.describe_availability_zones()
      end

      def get_instance_status(id)
        # Log.info "Checking instance with ID: '#{id}'"
        response = conn.describe_instances('instance-id' => id)
        unless response.nil?
          status = response.body['reservationSet'].first['instancesSet'].first['instanceState']['name'].to_sym
          launch_time = response.body['reservationSet'].first['instancesSet'].first['launchTime']
          { status: status, launch_time: launch_time, up_time_hours: ((Time.now - launch_time) / 1.hour).round }
        end
      end

      def vpc?(vpc_id)
        if aws_vpc = conn.vpcs.get(vpc_id)
           hash_form(aws_vpc)
        end
      end

      def subnets
        conn.subnets.map { |subnet| hash_form(subnet) }
      end

      def keypairs
        conn.key_pairs.map { |key_pair| hash_form(key_pair) }
      end
      def keypair?(keypair_name)
        if aws_key_pair = conn.key_pairs.get(keypair_name)
          hash_form(aws_key_pair)
        end
      end

      def subnet?(subnet_id)
        if subnet = conn.subnets.get(subnet_id)
          hash_form(subnet)
        end
      end

      def allocate_elastic_ip
        request_context do
          response = conn.allocate_address()
          if (response.status == 200)
            return response.body['publicIp']
          else
            Log.warn("Unable to allocate elastic IP from AWS, response: #{hash_form(response)}")
            nil
          end
        end
      end

      def release_elastic_ip(elastic_ip)
        # permently release elastic_ip
        request_context do
          hash_form(conn.release_address(elastic_ip))
        end
      end

      def disassociate_elastic_ip(elastic_ip)
        # removes elastic_ip from it's ec2 instance
        request_context do
          hash_form(conn.disassociate_address(elastic_ip))
        end
      end

      def associate_elastic_ip(instance_id, elastic_ip)
        request_context do
          hash_form(conn.associate_address(instance_id, elastic_ip))
        end
      end

      private

      def conn(key = nil)
        key.nil? ? @conn : (@override_conns[key] || @conn)
      end

      def wrap_servers_get(id)
        conn.servers.get(id)
      rescue Fog::Compute::AWS::Error => e
        Log.info("fog error: #{e.message}")
        nil
      end
    end
  end
end
