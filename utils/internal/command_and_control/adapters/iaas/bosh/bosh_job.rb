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
    # Has some informtion about a BOSH job
    #
    class BoshJob
      attr_reader :name, :num_instances, :static_ip_array
      def initialize(name, num_instances)
        @name = name
        @num_instances = num_instances
        @static_ip_array = compute_static_ip_array(name)
        @static_ips = compute_static_ips?(@static_ip_array)
      end

      def static_ips?
        @static_ips
      end

      private

      def compute_static_ips?(static_ip_array)
        unless static_ip_array.empty?
          "[#{static_ip_array.join(',')}]"
        end
      end

      # TODO: temp hack
      def compute_static_ip_array(job_name)
        if job_name =~ /master/
          [Bosh::BoshSubnet.master_static_ip]
        else
          []
        end
      end
    end
  end
end; end

