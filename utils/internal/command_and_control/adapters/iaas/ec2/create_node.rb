module DTK; module CommandAndControlAdapter
  class Ec2 
    #TODO: these fns that execute per node group member will be put at more asbtract level
    class CreateNode < self
      def self.run(task_action)
        base_node = task_action[:node]
        target = Target.get(base_node.model_handle(:target), task_action[:datacenter][:id])
        single_run_responses = target_ref_nodes(task_action,target).each do |create_single_node|
          create_single_node.run()
        end
        aggregate_responses(single_run_responses)
      end

     private
      def self.target_ref_nodes(task_action,target)
        nodes = task_action.nodes()
        #TODO: more efficient to get these attributes initially
        nodes.each do |node|
          node.update_object!(:os_type,:external_ref,:hostname_external_ref,:display_name,:assembly_id)
        end
        @target_ref_nodes = nodes.map{|node|TargetRef.new(node,target)}
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

        attr_reader :node,:target,:flavor_id,:external_ref
        def initialize(node,target)
          @node = node
          @target = target
          @external_ref = node[:external_ref]||{}
          @flavor_id = @external_ref[:size] || R8::Config[:command_and_control][:iaas][:ec2][:default_image_size]

        end

        def run()
          instance_id = external_ref[:instance_id]
          
          if instance_id
            Log.info("node already created with instance id #{instance_id}; waiting for it to be available")
          else
            response = create_ec2_instance()
            instance_id = response[:id]
            state = response[:state]
            updated_external_ref = external_ref.merge({
              :instance_id => instance_id,
              :type => "ec2_instance",
              :size => flavor_id
            })

            Log.info("#{node_print_form()} with ec2 instance id #{instance_id}; waiting for it to be available")
            Log.error('need to set node_update_hash :type')
            node_update_hash = {
              :external_ref => updated_external_ref,
              :type => Node::Type::Node.instance,
              :is_deployed => true,
              # TODO: better unify these below
              :operational_status => "starting",
              :admin_op_status => "pending"
            }
            Ec2.update_node!(node,node_update_hash)
          end
          
          process_addresses__first_boot?(node)
          
          {:status => "succeeded",
            :node => {
              :external_ref => external_ref
            }
          }
        end
       private
        def create_ec2_instance()
          response = nil
          unless ami = external_ref[:image_id]
            raise ErrorUsage.new("Cannot find ami for node (#{node[:display_name]})")
          end

          block_device_mapping_from_image = image(ami).block_device_mapping_with_delete_on_termination()
          create_options = {:image_id => ami,:flavor_id => flavor_id }
          # only add block_device_mapping if it was fully generated
          create_options.merge!({ :block_device_mapping => block_device_mapping_from_image }) if block_device_mapping_from_image
          # check priority for security group
          security_group = target.get_security_group() || external_ref[:security_group_set]||[R8::Config[:ec2][:security_group]]||"default"
          create_options.merge!(:groups => security_group )
          
          create_options.merge!(:tags => {"Name" => ec2_name_tag()})
          
          # check priority of keypair
          keypair = target.get_keypair_name() || R8::Config[:ec2][:keypair]

          create_options.merge!(:key_name => keypair)
          avail_zone = R8::Config[:ec2][:availability_zone] || external_ref[:availability_zone]
          
          unless avail_zone.nil? or avail_zone == "automatic"
            create_options.merge!(:availability_zone => avail_zone)
          end
          # end fix up
          
          unless create_options.has_key?(:user_data)
            if user_data = CommandAndControl.install_script(node)
              create_options[:user_data] = user_data
            end
          end
          
          if root_device_size = node.attribute.root_device_size()
            if device_name = image(ami).block_device_mapping_device_name()
              create_options[:block_device_mapping].first.merge!({'DeviceName' => device_name, 'Ebs.VolumeSize' => root_device_size})
            else
              Log.error("Cannot determine device name for ami (#{ami})")
            end

          end
            
          # we check if assigned target has aws credentials assigned to it, if so we will use those
          # credentials to create nodes
          target_aws_creds = node.get_target_iaas_credentials()
            
          begin
            response = Ec2.conn(target_aws_creds).server_create(create_options)
           rescue => e
            # append region to error message
            region = target.get_region() if target
            e.message << ". Region: '#{region}'." if region

            Log.error_pp([e,e.backtrace[0..10]])
            return {:status => "failed", :error_object => e}
          end
          response
        end

        def ec2_name_tag()
          assembly = node.get_assembly?()
          # TO-DO: move the tenant name definition to server configuration
          tenant = ::DtkCommon::Aux::running_process_user()
          subs = {
            :assembly => assembly && assembly.get_field?(:display_name),
            :node     => node.get_field?(:display_name),
            :tenant   => tenant,
            :target   => target[:display_name],
            :user     => CurrentSession.get_username()
          }
          ret = Ec2NameTag[:tag].dup
          Ec2NameTag[:vars].each do |var|
            val = subs[var]||var.to_s.upcase
            ret.gsub!(Regexp.new("\\$\\{#{var}\\}"),val)
          end
          ret
        end
        Ec2NameTag = {
          :vars => [:assembly, :node, :tenant, :target, :user],
          :tag => R8::Config[:ec2][:name_tag][:format]
        }

        def get_ec2_credentials(iaas_credentials)
          if iaas_credentials && (aws_key = iaas_credentials['key']) && (aws_secret = iaas_credentials['secret'])
            return { :aws_access_key_id => aws_key, :aws_secret_access_key => aws_secret }
          end
        end

        def node_print_form()
          "#{node[:display_name]} (#{node[:id]}"
        end
      end
    end
  end
end; end
