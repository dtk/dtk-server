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

      def self.exists?()
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

      private
      def value(attr)
        (@ami||{})[attr]
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
