module DTK; module CommandAndControlAdapter
  class Ec2
    module AddressManagementClassMixin
      def associate_elastic_ip(node)
        unless elastic_ip = node.elastic_ip()
          Log.error("associate_elastic_ip called but there is not allocated elastic ip for node with ID '#{node[:id]}")
          return
        end
        conn().associate_elastic_ip(node.instance_id(),node.elastic_ip())
      end

      #TODO: errors here should result in warning set to user that dns set wrong and will be ignored
      def associate_persistent_dns?(node)
        # check if it needs a persistent dns
        unless persistent_dns = node.persistent_dns()
          return
        end

        unless ec2_address = ec2_public_address!(node)
          Log.error("cannot find ec2_address in associate_persistent_dns for node with ID '#{node[:id]}")
          return
        end
        # we add record to DNS which links node's DNS to perssistent DNS
        dns = nil
        begin 
          dns = dns()
        rescue  => e
          err_msg = "cannot find ec2_address in associate_persistent_dns for node with ID '#{node[:id]}"
          if e.is_a?(::DTK::Error)
            err_msg << ": #{e}"
          end
          Log.error(err_msg)
          return
        end

        record = dns.get_record?(node.persistent_dns())
        
        if record.nil?
          # there is no record we need to create it (first boot)
          record = dns.create_record(node.persistent_dns(),ec2_address)
        else
          # we need to update it with new dns name
          record = dns.update_record(record,ec2_address)
        end

        # in case there was no record created we raise error
        raise Error, "Not able to set DNS hostname for node with ID '#{node[:id]}" if record.nil?

        # if all sucess we update the database
        node.update(hostname_external_ref: node[:hostname_external_ref])

        Log.info "Persistent DNS '#{node.persistent_dns()}' has been assigned to node and set as default DNS."
      end

      private

      def process_addresses__first_boot?(node)
        hostname_external_ref = {iaas: :aws }
        if node.persistent_hostname?()
          begin 
            # allocate elastic IP for this node
            elastic_ip = conn().allocate_elastic_ip()
            hostname_external_ref.merge!(elastic_ip: elastic_ip)
            external_ref.merge!(dns_name: elastic_ip) 
            Log.info("Persistent hostname needed for node '#{node[:display_name]}', assigned #{elastic_ip}")
           rescue Fog::Compute::AWS::Error => e
            Log.error "Not able to set Elastic IP, reason: #{e.message}"
            raise e
          end
        end
        if dns_assignment = DNS::R8.generate_node_assignment?(node)
          persistent_dns = dns_assignment.address()
          
          # we create it on node ready since we still do not have that data
          hostname_external_ref.merge!(persistent_dns: persistent_dns)
          Log.info("Persistent DNS needed for node '#{node[:display_name]}', assigned '#{persistent_dns}'")
        end
        node.update(hostname_external_ref: hostname_external_ref)
      end

      def process_addresses__restart(node)
        Log.info("in process_addresses__restart for node #{node[:display_name]}")
        # TODO: stub for feature_node_admin_state
      end

      def process_addresses__terminate?(node)
        unless node[:hostname_external_ref].nil? 
          if node.persistent_hostname?()
            unless elastic_ip = node.elastic_ip()
              Log.error("in process_addresses__terminate? call with node.persistent_hostname?, expecting an elastic ip for node with ID '#{node[:id]}")
              return
            end
            # no need for dissasociation since that will be done when instance is destroyed
            conn().release_elastic_ip(elastic_ip)
            Log.info "Elastic IP #{elastic_ip} has been released."
          end
          
          if persistent_dns = node.persistent_dns()
            success = nil

            dns = nil
            begin 
              dns = dns()
             rescue  => e
              err_msg = "in process_addresses__terminate? for node with ID '#{node[:id]}"
              if e.is_a?(::DTK::Error)
                err_msg << ": #{e}"
              end
              Log.error(err_msg)
              return
            end
            
            if success = dns.destroy_record(persistent_dns)
              Log.info "Persistent DNS has been released '#{node.persistent_dns()}', node termination continues."
            else
              Log.warn "System was not able to release '#{node.persistent_dns()}', for node ID '#{node[:id]}' look into this."
            end
          end
        end
      end

      def dns
        @dns ||= CloudConnect::Route53.new(::R8::Config[:dns][:r8][:domain])
      end
    end
  end
end;end
