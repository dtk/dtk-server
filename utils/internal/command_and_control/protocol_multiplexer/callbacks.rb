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
  module CommandAndControlAdapter
    class ProtocolMultiplexer
      class Callbacks < HashObject
        def self.create(callbacks_info)
          new(callbacks_info)
        end
        
        def self.process_error(callbacks, error_obj)
          unless callbacks && callbacks.process_error(error_obj)
            Log.error("Error in process_response: #{error_obj.inspect}")
            Log.error_pp(error_obj.backtrace)
          end
        end
        
        def process_msg(msg, request_id)
          if callback = self[:on_msg_received]
            callback.call(msg)
          else
            Log.error("Could not find process msg callback for request_id #{request_id}")
          end
        end
        
        def process_timeout(_request_id)
          if callback = self[:on_timeout]
            callback.call
          end
        end
        
        def process_cancel
          if callback = self[:on_cancel]
            callback.call 
          end
        end
        
        def cancel_timer
          DTKDebug.pp('Callbacks#cancel_timer', self)
          if timer = self[:timer]
            EventMachineHelper.cancel_timer(timer)
          end
        end
        
        def process_error(error_object)
          if callback = self[:on_error]
            callback.call(error_object)
            true
          end
        end
        
      end
    end
  end
end
