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
module DTK
  class CommandAndControl::IAAS::Bosh
    class Param
     # TODO: this is just temp and only works in docker container
      Keys = [:director, :vpc_subnet, :ec2_availability_zone, :subnet_range]
      def self.method_missing(name)
        get_bosh_param(name)
      end
      
      def self.respond_to?(name)
        Keys.include?(name) || super
      end
      
      private
      
      def self.get_bosh_param(param)
        get("bosh_#{param}")
      end
      
      def self.get(param)
        get_params![param.to_s] || fail(Error.new("Docker param '#{param}' is not set"))
      end
      
      ConfigFilePath = '/host_volume/dtk.config'
      def self.get_params!
        # Not caching so can dynamically read
        File.open('/host_volume/dtk.config').inject({}) do |h, line| 
          if line =~ /(^.+)=(.+$)/
            h.merge($1.downcase => $2) 
          else
            h
          end
        end
      end
    end
  end
end
