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
    # Has informtion needed to publish a BOSH manifest network subnet
    #
    class BoshSubnet
      attr_reader :range, :vpc_subnet, :ec2_availability_zone
      def initialize(bosh_jobs)
        @range                 = Bosh::Param.subnet_range
        @vpc_subnet            = Bosh::Param.vpc_subnet
        @ec2_availability_zone = Bosh::Param.ec2_availability_zone
        @static_addresses      = compute_static_addresses?(bosh_jobs)
      end

      def static_addresses?
        @static_addresses
      end

      def gateway
        # TODO: check if this is always the case
        ip_address(1)
      end
      
      def reserved_addresses
        # TODO: check if this is alwasta good range
        "[#{ip_address(2)}-#{ip_address(10)}]"
      end

      # TODO: hack
      # Nailed host
      StaticMasterHost = 50
      def self.master_static_ip
        ret = ip_address(StaticMasterHost, subnet24(Bosh::Param.subnet_range))
        Log.info("Generating static ip '#{ret}' for BOSH job 'master'")
        ret
      end

      private
      
      def compute_static_addresses?(bosh_jobs)
        ret_array = bosh_jobs.inject([]) { |a, bosh_job| a + bosh_job.static_ip_array }
        "[#{ret_array.join(',')}]" unless ret_array.empty? 
      end

      def ip_address(host_part)
        self.class.ip_address(host_part, subnet24)
      end
      def self.ip_address(host_part, subnet24)
        "#{subnet24}.#{host_part}"
      end

      # TODO: expand past treatment of /24 ranges
      def subnet24
        @subnet24 ||= self.class.subnet24(@range)
      end
      def self.subnet24(range)
        if range =~ /(^.+)\/24$/
          addr = $1
          addr.sub(/\.[0-9]+$/, '') 
        else
          fail ErrorUsage.new("Not supporting subnet '#{range}'; just /24 subnets")
        end
      end
    end
  end
end; end
