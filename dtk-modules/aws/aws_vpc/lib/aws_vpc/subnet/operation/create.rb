module DTKModule
  class Aws::Vpc
    class Subnet::Operation
      class Create < self
        require_relative('create/cidr_block')

        class InputSettings < DTK::Settings
          REQUIRED = [:vpc_id, :vpc_cidr_block, :subnet_length]
          OPTIONAL = [:subnet_cidr_block, :availability_zone, :enable_public_ip_in_subnet]
        end
        
        def create_subnet
          resp = client.create_subnet(initial_create_subnet_params)
          output_settings(resp.subnet)
          #internet_gateway_processing
        end
=begin
 subnet=
  #<struct Aws::EC2::Types::Subnet
   subnet_id="subnet-451cda1f",
   state="pending",
   vpc_id="vpc-366eef52",
   cidr_block="172.31.99.0/24",
   ipv_6_cidr_block_association_set=[],
   assign_ipv_6_address_on_creation=false,
   available_ip_address_count=251,
   availability_zone="us-east-1a",
   default_for_az=false,
   map_public_ip_on_launch=false,
   tags=[]>>
=end
        private
        
        def initial_create_subnet_params
          subnet_cidr_block = params.subnet_cidr_block || generate_subnet_cidr_block
          ret = {
            cidr_block: subnet_cidr_block,
            vpc_id: params.vpc_id
          }
          ret.merge!(availability_zone: params.availability_zone) if params.availability_zone
          ret
        end
          
        def internet_gateway_processing
          internet_gateways = get_internet_gateways
#          fail DTK::Error::Usage, "Debug: stopped here: internet gatways is #{internet_gateways.inspect}"
        end

        def generate_subnet_cidr_block
          existing_subnets = get_existing_subnet_cidr_blocks
          CidrBlock.generate_free_subnet_cidr_block(params.vpc_id, params.vpc_cidr_block, params.subnet_length, existing_subnets)
        end

        def get_existing_subnet_cidr_blocks
          Get.subnet_cidr_blocks_on_vpc(self, params.vpc_id)
        end

        def get_internet_gateways
          InternetGateway::Operation::Get.describe_internet_gateways(self, params.vpc_id)
        end
      end
    end
  end
end
