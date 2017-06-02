module DTKModule
  class Aws::Vpc
    class Subnet::Operation
      class Get < self
        class InputSettings < DTK::Settings
          OPTIONAL = [:subnet_id]
        end
        
        def describe_subnet
          if subnet_id = params.subnet_id
            output_settings_array = Get.describe_subnets(self, Filter::Subnet.new(subnet_id))
            case output_settings_array.size
            when 1 then output_settings_array.first
            when 0 then fail Error::Usage, "Illegal subnet id '#{subnet_id}'"
            else
              fail "Unexpected that output_settings_array.size > 1"
            end
          else # no subnet id
            # See if can discover subnet that ec2 instance is on
            if vpc_info = VpcInfo.get_from_ec2_instance_meta_data?
              Subnet::OutputSettings.map_from_ec2_metadata_vpc_info(vpc_info)
            end
          end
        end

        class ClassMethod < OperationBase::ClassMethod
          # Returns an array of Subnet::OutputSettings; filter of type Filter
          def describe_subnets(filters)
            filters = [filters] unless filters.kind_of?(::Array)
            aws_subnet_result = client.describe_subnets(filters: filters.map(&:hash)).subnets
            output_settings_array(aws_subnet_result)
          end

          def subnet_cidr_blocks_on_vpc(vpc_id)
            subnets_on_vpc(vpc_id).map { |output_settings| output_settings[:subnet_cidr_block] }
          end
          
          def subnets_on_vpc(vpc_id)
            describe_subnets(Filter::Vpc.new(vpc_id))
          end
        end

      end
    end
  end
end

