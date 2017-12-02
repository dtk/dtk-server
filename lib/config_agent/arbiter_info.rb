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
  class ConfigAgent
    module ArbiterInfo
      PROTOCOL_VERSION = 2
      DTK_MODULE_ROOT = '/usr/share/dtk/modules'
      DTK_3304_PROTOCOL_VERSION = 1 # TODO: temp until arbiters are upgraded
      
      # opts can have keys:
      #  :service_instance_name
      def self.dtk_module_base(opts = {})
        case PROTOCOL_VERSION
        when 1
          dtk_module_base_protocol1
        when 2
          if dtk_3304_hack_use_protocol1?
            dtk_module_base__protocol1
          else
            dtk_module_base__protocol2(opts[:service_instance_name])
          end
        else
          fail Error, "Unexpected protocol version '#{PROTOCOL_VERSION}'"
        end
      end
      
      private
      
      def self.dtk_module_base__protocol1
        DTK_MODULE_ROOT
      end
      
      def self.dtk_module_base__protocol2(service_instance_name)
        fail Error, "Unexpected that self.service_instance_name is nil" unless service_instance_name
        "#{DTK_MODULE_ROOT}/#{service_instance_name}"
      end
      
      def self.dtk_3304_hack_use_protocol1?
        if constants.include?(:DTK_3304_PROTOCOL_VERSION)
          DTK_3304_PROTOCOL_VERSION == 1
        end
      end
      
    end
  end
end
