require 'ipaddress'
module DTKModule
  class Aws::Vpc::Subnet::Operation::Create
    module CidrBlock
      def self.generate_free_subnet_cidr_block(vpc_id, vpc_cidr_block, subnet_length, existing_subnets)
        existing_subnet_ranges = existing_subnets.map { |subnet| SubnetRange.new(subnet) }
        free_subnet = potential_subnet_cidr_blocks(vpc_cidr_block, subnet_length).find do |subnet_cidr_block| 
          subnet_range = SubnetRange.new(subnet_cidr_block)
          ! SubnetRange.overlap?(subnet_range, existing_subnet_ranges)
        end
        free_subnet || fail(DTK::Error::Usage, "No free subnets on vpc '#{vpc_id}' of length #{subnet_length}")
      end

      private
      
      def self.potential_subnet_cidr_blocks(vpc_cidr_block, subnet_length)
        vpc_cidr_ipaddress = ::IPAddress.parse(vpc_cidr_block)
        vpc_cidr_length    = vpc_cidr_ipaddress.prefix.to_i

        unless subnet_length > vpc_cidr_length
          fail DTK::Error::Usage, "Subnet length, which is set to #{subnet_length}, must be greater than vpc cidr length (#{vpc_cidr_length})"
        end
        vpc_cidr_ipaddress.subnet(subnet_length).map(&:to_string)
      end
      
      class SubnetRange
        attr_reader :begin_int, :end_int
        def initialize(cidr_block)
          @begin_int = ::IPAddress.parse(cidr_block).first.u32
          @end_int   = ::IPAddress.parse(cidr_block).last.u32
        end
        private :initialize
        
        def self.overlap?(subnet_range, existing_subnet_ranges)
          existing_subnet_ranges.find { |existing_range| subnet_range.overlap?(existing_range) }
        end

        def overlap?(existing_range)
          not_overlap = ((begin_int > existing_range.end_int) or (existing_range.begin_int > end_int))
          !not_overlap
        end

      end
    end
  end
end
