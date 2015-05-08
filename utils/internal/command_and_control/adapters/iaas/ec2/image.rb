module DTK; module CommandAndControlAdapter
  class Ec2
    module ImageClassMixin
      def image(image_id,opts={})
        Image.new(image_id,opts)
      end
    end

    class Image
      def initialize(image_id,opts={})
        aws_creds = nil
        if target = opts[:target]
          aws_creds = Ec2.target_non_default_aws_creds?(target)
        end
        @ami = Ec2.conn(aws_creds).image_get(image_id)
      end

      def exists?()
        !!@ami
      end
        
      def root_device_name()
        value(:root_device_name)
      end

      def block_device_mapping?(root_device_override_attrs={})
        if default_block_device_mappings = value(:block_device_mapping)
          BlockDeviceMapping.ret(default_block_device_mapping,root_device_override_attrs)
        end
      end

     private
      def value(attr)
        (@ami||{})[attr]
      end

      module BlockDeviceMapping
        def self.ret(default_block_device_mapping,root_device_override_attrs={})
          block_device_mapping = update_root_device(block_device_mapping,root_device_override_attrs)
          convert_keys(block_device_mapping)
        end
       private
        def self.update_root_device(block_device_mapping,root_device_override_attrs={})
          ret = block_device_mapping
          unless root_device_override_attrs.empty?
            size = root_device_override_attrs.size
            # TODO: assuming route device is first element in array default_block_device_mapping; need to further validate
            [root_device_override_attrs.first.merge(root_device_override_attrs)] + root_device_override_attrs[1..size-1]
          else
            ret
          end
        end

        def self.convert_keys(block_device_mapping)
          block_device_mapping.map do |one_mapping|
            one_mapping.inject(Hash.new) do |h,(k,v)|
            
          end
        end
        KeyMapping = {
          'deviceName'          => 'DeviceName',
          'snapshotId'          => 'Ebs.SnapshotId',
          'volumeSize'          => 'Ebs.VolumeSize',
          'deleteOnTermination' => 'Ebs.DeleteOnTermination',
          'virtualName'         => 'VirtualName',
        }


      def create_block_device_mapping(image_mappings)
        block_device_mapping = []

        image_mappings.each do |image_mapping|
          mapping = {}
          name_mapping.each do |key, value|
            mapping[value] = image_mapping[key] unless image_mapping[key].nil?
          end
          block_device_mapping << mapping
        end
        block_device_mapping
      end


          block_device_mapping = create_block_device_mapping(block_device_mappingvalue(:block_device_mapping))
          block_device_mapping.first["Ebs.DeleteOnTermination"] = "true"
          block_device_mapping
        end
      end
    


    end
  end
end; end
