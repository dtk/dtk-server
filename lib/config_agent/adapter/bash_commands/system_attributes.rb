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
module DTK; class ConfigAgent; module Adapter
  class BashCommands
    class SystemAttributes
      def initialize(component_module_name, assembly_instance)
        @component_module_name = component_module_name
        @assembly_instance     = assembly_instance
      end
      private :initialize

      # opts can have keys:
      #  :assembly_instance
      def self.attribute_value_hash(component_module_name, opts = {})
        if opts[:assembly_instance]
          new(component_module_name, opts[:assembly_instance]).attribute_value_hash
        else
          {}
        end
      end
      
      def attribute_value_hash
        {
          dtk: {
            module: {
              dir: self.dtk_module_dir
            }
          }
          
        }
      end
      
      protected

      attr_reader :component_module_name, :assembly_instance

      def dtk_module_dir
        @dtk_module_dir ||= "#{self.dtk_module_base}/#{self.component_module_name}" 
      end

      def dtk_module_base
        @dtk_module_base ||= ArbiterInfo.dtk_module_base(service_instance_name: self.service_instance_name)
      end

      def service_instance_name
        @service_instance_name ||=  self.assembly_instance.display_name
      end
      
    end
  end
end; end; end
