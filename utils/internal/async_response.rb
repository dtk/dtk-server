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
  class AsyncResponse
    include ::EventMachine::Deferrable
    def self.create(async_callback, content_type, response_procs, &blk)
      deferred_body = new(response_procs)
      ::EventMachine.next_tick do #TODO: is next_tick necessary?
        async_callback.call [200, { 'Content-Type' => content_type }, deferred_body]
      end

      user_object  = ::DTK::CurrentSession.new.user_object()
      CreateThread.defer_with_session(user_object, Ramaze::Current.session) do
        begin
          # TODO: to allow simpler form where blk does not have a handle parameter
          # can case on whether this is the case and if not call
          # data = blk.call()
          # deferred_body.rest_ok_response(data)
          blk.call(deferred_body)
        rescue => e
          deferred_body.rest_notok_response(e)
        end
      end
      throw :async
    end

    def rest_ok_response(data)
      push_data(@response_procs[:ok].call(data))
      signal_eos()
    end

    def rest_notok_response(data)
      push_data(@response_procs[:notok].call(data))
      signal_eos()
    end

    # needed by rack/thin
    def each(&blk)
      @body_callback = blk
    end

    private

    def initialize(response_procs)
      @response_procs = response_procs
      super()
    end

    def push_data(data)
      ::EventMachine.next_tick do
        @body_callback.call data
      end
    end

    def signal_eos
      ::EventMachine.next_tick do
        succeed()
      end
    end
  end
end