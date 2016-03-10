#
# Copyright (C) 2010-2016 dtk contributors
#
# This file is part of the dtk project.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
module DTK; class CommandAndControl::IAAS
  class Bosh
    ##
    # Has informtion needed to public a BOSH manifest network subnet
    #
    class BoshSubnet
      attr_reader :range, :vpc_subnet, :ec2_availability_zone
      def inititialize
        @range                 = Bosh::Param.subnet_range
        @vpc_subnet            = Bosh::Param.vpc_subnet
        @ec2_availability_zone = Bosh::Param.ec2_availability_zone
        @static_hosts          = StaticHosts
      end

      # TODO: arbitrary
      StaticHosts = (50..60).map{ |num| num}

      def gateway
        # TODO: check if this is always the case
        ip_address(1)
      end
    
      def reserved_addresses_string
        "[#{ip_address(2)}-#{ip_address(10)}]"
      end

      def static_addresses_array
        @static_hosts.map { |h| ip_address(h) }
      end

      private

      def ip_address(host_part)
        "#{subnet24}.#{host_part}"
      end

      def subnet24
        # TODO: just treat /24 ranges
        unless @subnet24
          if @range =~ /(^.+)\/24$/
            addr = $1
            @subnet_par = add.sub(/\.[0-9]+$/, '') 
          else
            fail ErrorUsage.new("Not supporting subnet '#{@range}', just \24 subnets")
          end
        end
        @subnet_par
      end
    end
  end
end; end
