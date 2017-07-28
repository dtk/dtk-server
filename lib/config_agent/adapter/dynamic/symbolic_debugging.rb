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
  class ConfigAgent::Adapter::Dynamic
    class SymbolicDebugging
      module Mixin
        def process_if_involved_in_symbolic_debugging(task, action, payload)
          name_value_hash = dynamic_attribute_name_raw_value_hash(payload)
          SymbolicDebugging.new(task, action, name_value_hash).process_if_involved_in_symbolic_debugging
        end
      end
      
      def initialize(task, action, name_value_hash)
        @task            = task
        @action          = action
        @name_value_hash = name_value_hash
      end
      
      def process_if_involved_in_symbolic_debugging
        if public_dns_name = value?(:public_dns_name)
          $public_dns = public_dns_name
        end
        
        if dtk_debug_port = value?(:dtk_debug_port)
          $remember = true
          debug = true
          if method_name = action.action_method?
            debug = false if method_name[:method_name].eql?('delete')
          end
          
          if $port_number.nil? || !$port_number.eql?(dtk_debug_port)
            $port_number = dtk_debug_port
          end
          
          $public_dns = nil unless $remember
          
          self.task.add_event(:info, port_message($port_number, $public_dns))
        else
          $public_dns = nil unless $remember
          $port_number = nil
        end
      end

      protected

      attr_reader :task, :action, :name_value_hash
    
      KEY_MAPPING = { 
        public_dns_name: 'public_dns_name',
        dtk_debug_port: 'dtk_debug_port'
      }

      private

      def port_message(port_number, public_dns)
        byebug_ref = (public_dns.nil? ? port_number : "#{public_dns}:#{port_number}")
        # TODO: Give name of action
        { info: "Please use 'byebug -R #{byebug_ref}' to debug current action."}
      end
      

      def value?(symbol_key)
        unless key = KEY_MAPPING[symbol_key]
          fail Error, "Illegal key '#{key}'"
        end
        self.name_value_hash[key]
      end
   
    end
  end
end
