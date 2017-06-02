module DTKModule
  class Aws::Vpc
    class Subnet < self
      require_relative('subnet/operation')
      require_relative('subnet/output_settings')

      # returns dynamic_attributes encoded in OutputSettings object
      def self.converge(credentials_handle, name, attributes)
        new(credentials_handle, name, attributes).converge
      end
      def converge
        dynamic_attributes = 
          if attributes.value?(:discovered) or attributes.value?(:subnet_id)
            get_dynamic_attributes
          else
            aws_api_operation(:create).create_subnet
          end

        dynamic_attributes.merge(region: region).merge(dynamic_attribute_images? || {})
      end
      
      # returns dynamic_attributes encoded in OutputSettings object
      def self.delete(credentials_handle, name, attributes)
        new(credentials_handle, name, attributes).delete
      end
      def delete
        subnet_id = attributes.value?(:subnet_id)
        if subnet_id and not attributes.value?(:discovered)
          aws_api_operation(:delete).delete_subnet
            OutputSettings.nil_values_after_delete
        else
          OutputSettings.empty
        end
      end
      
      private
      
      # returns dynamic_attributes encoded in OutputSettings object
      # Raises error if cant find a unique sunet
      def get_dynamic_attributes
        aws_api_operation(:get).describe_subnet
      end

      def dynamic_attribute_images?
        (attributes.value?(:images_all_regions) || {})[region]
      end

    end
  end
end

