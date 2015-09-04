# TODO: cleanup use of request_context
module DTK
  class CloudConnect
    class EC2 < self
      r8_nested_require('ec2', 'image_info_cache')

      WAIT_FOR_NODE = 10 # seconds

      # TODO: find cleaner way than having multiple @conn objects
      def initialize(override_of_aws_params = nil)
        base_params = override_of_aws_params || get_compute_params()
        @conn = Fog::Compute::AWS.new(base_params)
        @override_conns = OverrideConnectionOptions.inject({}) do |h, (k, conn_opts)|
          h.merge(k => Fog::Compute::AWS.new(base_params.merge(connection_options: conn_opts)))
        end
      end

      OverrideConnectionOptions = {
        # Setting retry_limit to 1, but using a mutex at a outer level to retry
        server_create: { read_timeout: 5, retry_limit: 1 }
      }

      def conn(key = nil)
        key.nil? ? @conn : (@override_conns[key] || @conn)
      end

      private :conn

      def flavor_get(id)
        hash_form(conn.flavors.get(id))
      end

      def image_get(id)
        ImageInfoCache.get_or_set(:image_get, conn, id, mutex: true) do
          hash_form(conn.images.get(id))
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

      def security_groups_all
        conn.security_groups.all.map { |x| hash_form(x) }
      end

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

      def check_for_key_pair(name)
        unless key_pair = conn.key_pairs.get(name)
          fail ErrorUsage.new("Not able to find IAAS keypair with name '#{name}' aborting action, please create necessery keypair")
          # key_pair = conn.key_pairs.create(:name => name)
        end
        key_pair
      end

      def check_for_subnet(subnet_id)
        subnets = conn.subnets
        unless subnet_obj = subnets.get(subnet_id)
          err_msg = "Not able to find IAAS subnet with id '#{subnet_id}'"
          if subnets.empty?
            err_msg << '; there are no subnets created in the vpc'
          else
            avail_subnets = subnets.map { |s| hash_form(s)[:subnet_id] }
            err_msg << "; set the target to use one of the available subnets: #{avail_subnets.join(', ')}"
          end
          fail ErrorUsage.new(err_msg)
        end
        subnet_obj.subnet_id
      end

      def check_for_security_group(name, _description = nil)
        return unless conn.respond_to?(:security_groups)
        unless sc = conn.security_groups.get(name)
          # sc = conn.security_groups.create(:name => name, :description => description)
          fail ErrorUsage.new("Not able to find IAAS security group with name '#{name}' aborting action, please create necessery security group")
        end
        sc
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

      def wrap_servers_get(id)
        conn.servers.get(id)
      rescue Fog::Compute::AWS::Error => e
        Log.info("fog error: #{e.message}")
        nil
      end
    end
  end
end
