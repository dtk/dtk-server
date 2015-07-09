module DTK; module CommandAndControlAdapter
  class Ec2
    module ImageClassMixin
      def image(image_id, opts = {})
        Image.new(image_id, opts)
      end
    end

    class Image
      def initialize(image_id, opts = {})
        aws_creds = nil
        if target = opts[:target]
          aws_creds = Ec2.target_non_default_aws_creds?(target)
        end
        @ami = Ec2.conn(aws_creds).image_get(image_id)
      end

      def exists?
        !!@ami
      end

      def root_device_name
        value(:root_device_name)
      end

      def block_device_mapping?(root_device_override_attrs = {})
        if default_block_device_mapping = value(:block_device_mapping)
          BlockDeviceMapping.ret(default_block_device_mapping, root_device_override_attrs)
        end
      end

      private

      def value(attr)
        (@ami || {})[attr]
      end

      module BlockDeviceMapping
        def self.ret(default_block_device_mapping, root_device_override_attrs = {})
          block_device_mapping = convert_and_prune_keys(default_block_device_mapping)
          update_root_device_with_overrides(block_device_mapping, root_device_override_attrs)
        end

        private

        def self.update_root_device_with_overrides(block_device_mapping, root_device_override_attrs = {})
          ret = block_device_mapping
          overrides = root_device_override_attrs.reject do |k, _v|
            unless TargetKeys.include?(k)
              Log.error("Bad key '#{k}' in root_device_override_attrs")
              true
            end
          end
          unless overrides.empty?
            size = block_device_mapping.size
            # TODO: assuming route device is first element in array block_device_mapping; need to further validate
            [block_device_mapping.first.merge(root_device_override_attrs)] + block_device_mapping[1..size]
          else
            ret
          end
        end

        def self.convert_and_prune_keys(block_device_mapping)
          block_device_mapping.map do |one_mapping|
            KeyMapping.inject({}) do |h, (k1, k2)|
              one_mapping.key?(k1) ? h.merge(k2 => one_mapping[k1]) : h
            end
          end
        end
        KeyMapping = {
          'deviceName'          => 'DeviceName',
          'snapshotId'          => 'Ebs.SnapshotId',
          'volumeSize'          => 'Ebs.VolumeSize',
          'deleteOnTermination' => 'Ebs.DeleteOnTermination',
          'virtualName'         => 'VirtualName'
        }
        TargetKeys = KeyMapping.values
      end
    end
  end
end; end
