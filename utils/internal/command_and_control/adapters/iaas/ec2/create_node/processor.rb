module DTK; module CommandAndControlAdapter
  class Ec2
    class CreateNode < self
      class Processor
        r8_nested_require('processor', 'create_options')

        #using include on class mixins because this class is instance based, not class based
        include NodeStateClassMixin
        include AddressManagementClassMixin
        include ImageClassMixin

        attr_reader :base_node, :node, :target, :flavor_id, :external_ref
        def initialize(base_node, node, target)
          @base_node    = base_node
          @node         = node
          @target       = target
          @external_ref = node[:external_ref] || {}
          @flavor_id    = @external_ref[:size] || R8::Config[:command_and_control][:iaas][:ec2][:default_image_size]
        end

        def run
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
            updated_external_ref = @external_ref.merge(
              instance_id: instance_id,
              type: 'ec2_instance',
              size: flavor_id
            )

            Log.info("#{node_print_form()} with ec2 instance id #{instance_id}; waiting for it to be available")
            node_update_hash = {
              external_ref: updated_external_ref,
              type: Node::Type.new_type_when_create_node(base_node),
              is_deployed: true,
              # TODO: better unify these below
              operational_status: 'starting',
              admin_op_status: 'pending'
            }
            update_node!(node_update_hash)
          end

          process_addresses__first_boot?(@node)

          { status: 'succeeded',
            node: {
              external_ref: @external_ref
            }
          }
        end

        private

        def generate_client_token?
          unless @external_ref[:client_token]
            # generate client token
            client_token = @external_ref[:client_token] = Ec2::ClientToken.generate()
            Log.info("Generated client token '#{client_token}' for node '#{node_print_form()}'")
            updated_external_ref = external_ref.merge(client_token: client_token)
            update_node!(external_ref: updated_external_ref)
          end
        end

        def update_node!(node_update_hash)
          Ec2.update_node!(@node, node_update_hash)
          if er = node_update_hash[:external_ref]
            @external_ref = er
          end
          @node.merge!(node_update_hash)
        end

        def create_ec2_instance
          response = nil
          unless ami = @external_ref[:image_id]
            fail ErrorUsage.new("Cannot find ami for node (#{@node[:display_name]})")
          end

          conn = Ec2.conn(@node.get_target_iaas_credentials())

          create_options = CreateOptions.new(self, conn, ami)

          create_options.update_security_group!()
          create_options.update_tags!()
          create_options.update_key_name()
          create_options.update_availability_zone!()
          create_options.update_vpc_info?()
          create_options.update_block_device_mapping!(image(ami, target: @node.get_target()))
          create_options.update_user_data!()
          create_options.update_client_token?()

          begin
            response = conn.server_create(create_options)
            response[:status] ||= 'succeeded'
           rescue => e
            # append region to error message
            region = target.get_region() if target
            e.message << ". Region: '#{region}'." if region

            Log.error_pp([e, e.backtrace[0..10]])
            return { status: 'failed', error_object: e }
          end
          response
        end

        def get_node_status(instance_id)
          ret = nil
          begin
            target_aws_creds = node.get_target_iaas_credentials()
            response = Ec2.conn(target_aws_creds).get_instance_status(instance_id)
            ret = response[:status] && response[:status].to_sym
          rescue => e
            Log.error_pp([e, e.backtrace[0..10]])
          end
          ret
        end

        def node_print_form
          "#{node[:display_name]} (#{node[:id]})"
        end
      end
    end
  end
end; end
