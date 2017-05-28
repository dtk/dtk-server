module DTKModule
  class Ec2::Node::Operation
    class Create <  self
      require_relative('create/user_data')
      require_relative('create/aws_form')

      class InputSettings < DTK::Settings
        REQUIRED = [:dtk_agent_info, :client_token, :os_type, :image_id, :instance_type, :security_group_ids, :subnet_id]
        OPTIONAL = [:iam_instance_profile, :key_name, :block_device_mappings, :instance_id, :tags, :enable_public_ip_in_subnet]
      end

      # Returns an InstanceInfo object
      def create_instance
        create_instances(1).first
      end

      # Returns an array of InstanceInfo objects
      def create_instances(count)
        result = client.run_instances(AwsForm.map(params.merge(count: count)))
        instance_ids  = result.instances.map(&:instance_id)
        ret = wait_for_create(instance_ids)
        # need to make sure add_tags is done after after wait_until or can have error that instance ids dont exist
        add_tags?(instance_ids, with_dtk_tag: true)
        IamInstanceProfile.set_iam_instance_profiles(self, instance_ids, params.iam_instance_profile) unless params.iam_instance_profile.nil?
        ret
      end

        
      private

      DTK_TAG = { 'dtk_application' =>  'true' }
      # opts can have keys
      #  :with_dtk_tag
      def add_tags?(instance_ids, opts = {})
        tags = params.tags
        (tags ||= {}).merge!(DTK_TAG) if opts[:with_dtk_tag]
        if tags
          client.create_tags(resources: instance_ids, tags: tags.map { |k, v| { key: k, value: v } })
        end
      end

    end
  end
end
