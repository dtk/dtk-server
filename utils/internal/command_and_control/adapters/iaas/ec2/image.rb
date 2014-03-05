module DTK; module CommandAndControlAdapter
  class Ec2
    module ImageClassMixin
      def image(image_id)
        Image.new(image_id)
      end
    end

    class Image

      def initialize(image_id)
        @ami = Ec2.conn().image_get(image_id)
      end

      def exists?()
        !!@ami
      end
        
      def root_device_name()
        value(:root_device_name)
      end
      def block_device_mapping_device_name()
        if bdm = single_block_device_mapping?()
          bdm['deviceName']
        end
      end

      def block_device_mapping_with_delete_on_termination()
        return nil unless value(:block_device_mapping)
        block_device_mapping = create_block_device_mapping(value(:block_device_mapping))
        block_device_mapping.first["Ebs.DeleteOnTermination"] = "true"
        block_device_mapping
      end

      private

      def value(attr)
        (@ami||{})[attr]
      end

      def create_block_device_mapping(image_mappings)
        block_device_mapping = []
        name_mapping = {
          'deviceName' => 'DeviceName',
          'snapshotId' => 'Ebs.SnapshotId',
          'volumeSize' => 'Ebs.VolumeSize',
          'deleteOnTermination' => 'Ebs.DeleteOnTermination',
        }
        image_mappings.each do |image_mapping|
          mapping = {}
          name_mapping.each do |key, value|
            mapping[value] = image_mapping[key]
          end
          block_device_mapping << mapping
        end
        block_device_mapping
      end

      def single_block_device_mapping?()
        if bdm = value(:block_device_mapping)
          case bdm.size
            when 0 then nil
            when 1 then bdm.first
            else 
              Log.error("Call to single_block_device_mapping? when more than one blocks defined")
              nil
          end
        end
      end
    end
  end
end; end
