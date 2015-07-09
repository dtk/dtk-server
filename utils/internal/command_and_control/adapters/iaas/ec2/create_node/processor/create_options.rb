module DTK; module CommandAndControlAdapter
  class Ec2::CreateNode; class Processor
    class CreateOptions < ::Hash
      def initialize(parent,conn,ami)
        super()
        replace(image_id: ami,flavor_id: parent.flavor_id)
        @conn         = conn
        @target       = parent.target
        @node         = parent.node
        @external_ref = parent.external_ref||{}
      end
      
      def update_security_group!
        security_group = @target.get_security_group() || 
          @target.get_security_group_set() || 
          @external_ref[:security_group_set] ||
          [R8::Config[:ec2][:security_group]] ||
          'default'
        merge!(groups: security_group)
      end
      
      def update_tags!
        merge!(tags: {"Name" => ec2_name_tag()})
      end
      
      def update_key_name
        merge!(key_name: @target.get_keypair() || R8::Config[:ec2][:keypair])
      end
      
      def update_availability_zone!
        target_availability_zone = (@target[:iaas_properties]||{})[:availability_zone]
        avail_zone = @external_ref[:availability_zone] || 
          (@target[:iaas_properties]||{})[:availability_zone] || 
          R8::Config[:ec2][:availability_zone]
        unless avail_zone.nil? || avail_zone == 'automatic'
          merge!(availability_zone: avail_zone)
        end
      end
      
      def update_vpc_info?
        if @target.is_builtin_target?()
          #TODO: we wil get rid of this special case and just put the info in builtin target
          if R8::Config[:ec2][:vpc_enable]
            subnet_id = @conn.check_for_subnet(R8::Config[:ec2][:vpc][:subnet_id])
            merge!(subnet_id: subnet_id, associate_public_ip: R8::Config[:ec2][:vpc][:associate_public_ip])
            merge!(groups: R8::Config[:ec2][:vpc][:security_group])
            return
          end
        end
        
        unless iaas_properties = @target[:iaas_properties]
          Log.error_pp(["Unexpected that @target does not have :iaas_properties",@target])
          return
        end
        
        unless iaas_properties[:ec2_type] == 'ec2_vpc'
          return
        end
        
        unless subnet = iaas_properties[:subnet]
          Log.error_pp(["Unexpected that @target does not have :iaas_properties",@target])
          return
        end
        
        subnet_id = @conn.check_for_subnet(subnet)
        associate_public_ip = true #TODO: stub vale
        merge!(subnet_id: subnet_id, associate_public_ip: associate_public_ip) 
      end
      
      def update_block_device_mapping!(image)
        root_device_override_attrs = {'Ebs.DeleteOnTermination' => 'true'}
        if root_device_size = @node.attribute.root_device_size() 
          root_device_override_attrs.merge!('Ebs.VolumeSize' => root_device_size)
        end
        # only add block_device_mapping if it was fully generated
        if block_device_mapping = image.block_device_mapping?(root_device_override_attrs)
          merge!(block_device_mapping: block_device_mapping)
        end
      end
      
      def update_user_data!
        self[:user_data] ||= CommandAndControl.install_script(@node)
        self
      end

      def update_client_token?()
        if client_token = @external_ref[:client_token]
          self[:client_token] ||= client_token
        else
          Log.error_pp(["Unexpected that @external_ref does not have client_token",@node,@external_ref])
        end
        self
      end

      private
      
      def ec2_name_tag
        # TO-DO: move the tenant name definition to server configuration
        tenant = ::DtkCommon::Aux::running_process_user()
        subs = {
          assembly: ec2_name_tag__get_assembly_name(),
          node: @node.get_field?(:display_name),
          tenant: tenant,
          target: @target[:display_name],
          user: CurrentSession.get_username()
        }
        ret = Ec2NameTag[:tag].dup
        Ec2NameTag[:vars].each do |var|
          val = subs[var]||var.to_s.upcase
          ret.gsub!(Regexp.new("\\$\\{#{var}\\}"),val)
        end
        ret
      end
      Ec2NameTag = {
        vars: [:assembly, :node, :tenant, :target, :user],
        tag: R8::Config[:ec2][:name_tag][:format]
      }
      
      def ec2_name_tag__get_assembly_name
        if assembly = @node.get_assembly?()
          assembly.get_field?(:display_name)
        else
          node_ref = @node.get_field?(:ref)
          # looking for form base_node_link--ASSEMBLY::NODE-EDLEMENT-NAME
          if node_ref =~ /^base_node_link--([^:]+):/
            $1
          else
            Log.error_pp(["Unexepected that cannot determine assembly name for node",@node])
          end
        end
      end

    end
  end; end
end; end
