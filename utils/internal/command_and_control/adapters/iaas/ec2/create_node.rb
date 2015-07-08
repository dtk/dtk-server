module DTK; module CommandAndControlAdapter
  class Ec2
    #TODO: these fns that execute per node group member will be put at more asbtract level
    class CreateNode < self
      def self.run(task_action)
        single_run_responses = target_ref_nodes(task_action).map(&:run)
        aggregate_responses(single_run_responses)
      end

      private

      def self.target_ref_nodes(task_action)
        nodes = task_action.nodes()
        nodes.each do |node|
          node.update_object!(:os_type,:external_ref,:hostname_external_ref,:display_name,:assembly_id)
        end
        target = task_action.target()
        base_node = task_action.base_node()
        nodes.map{|node|TargetRef.new(base_node,node,target)}
      end

      def self.aggregate_responses(single_run_responses)
        if single_run_responses.size == 1
          single_run_responses.first
        else
          #TODO: just finds first error now
          if first_error = single_run_responses.find{|r|r[:status] == "failed"}
            first_error
          else
            #assuming all ok responses are the same
            single_run_responses.first
          end
        end
      end

      class TargetRef
        #using include on class mixins because this class is insatnce based, not class based
        include NodeStateClassMixin
        include AddressManagementClassMixin
        include ImageClassMixin

        attr_reader :base_node,:node,:target,:flavor_id,:external_ref
        def initialize(base_node,node,target)
          @base_node = base_node
          @node = node
          @target = target
          @external_ref = node[:external_ref]||{}
          @flavor_id = @external_ref[:size] || R8::Config[:command_and_control][:iaas][:ec2][:default_image_size]
        end

        def run
          create_node = true
          if instance_id = external_ref[:instance_id]
            # handle case where node is terminated and need to recreate
            if get_node_status(instance_id) == :terminated
              Log.info("node instance id #{instance_id} has been terminated; creating new node")
            else
              create_node = false
              Log.info("node already created with instance id #{instance_id}; waiting for it to be available")
            end
          end
          if create_node
            response = create_ec2_instance()
            if response[:status] == "failed"
              return response
            end

            instance_id = response[:id]
            state = response[:state]
            updated_external_ref = external_ref.merge(              instance_id: instance_id,
              type: "ec2_instance",
              size: flavor_id)

            Log.info("#{node_print_form()} with ec2 instance id #{instance_id}; waiting for it to be available")
            node_update_hash = {
              external_ref: updated_external_ref,
              type: Node::Type.new_type_when_create_node(base_node),
              is_deployed: true,
              # TODO: better unify these below
              operational_status: "starting",
              admin_op_status: "pending"
            }
            Ec2.update_node!(node,node_update_hash)
          end

          process_addresses__first_boot?(node)

          {status: "succeeded",
            node: {
              external_ref: external_ref
            }
          }
        end

        private

        def create_ec2_instance
          response = nil
          unless ami = external_ref[:image_id]
            raise ErrorUsage.new("Cannot find ami for node (#{@node[:display_name]})")
          end

          conn = Ec2.conn(@node.get_target_iaas_credentials())

          create_options = CreateOptions.new(self,conn,ami)

          create_options.update_security_group!()
          create_options.update_tags!()
          create_options.update_key_name()
          create_options.update_availability_zone!()
          create_options.update_vpc_info?()
          create_options.update_block_device_mapping!(image(ami))
          create_options.update_user_data!()

          begin
            response = conn.server_create(create_options)
            response[:status] ||= "succeeded"
           rescue => e
            # append region to error message
            region = target.get_region() if target
            e.message << ". Region: '#{region}'." if region

            Log.error_pp([e,e.backtrace[0..10]])
            return {status: "failed", error_object: e}
          end
          response
        end

        class CreateOptions < Hash
          def initialize(target_ref,conn,ami)
            super()
            replace(image_id: ami,flavor_id: target_ref.flavor_id)
            @conn         = conn
            @target       = target_ref.target
            @node         = target_ref.node
            @external_ref = target_ref.external_ref||{}
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

        def get_node_status(instance_id)
          ret = nil
          begin
            target_aws_creds = node.get_target_iaas_credentials()
            response = Ec2.conn(target_aws_creds).get_instance_status(instance_id)
            ret = response[:status] && response[:status].to_sym
           rescue => e
             Log.error_pp([e,e.backtrace[0..10]])
          end
          ret
        end

        def node_print_form
          "#{node[:display_name]} (#{node[:id]}"
        end
      end
    end
  end
end; end
