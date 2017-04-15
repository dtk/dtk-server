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
require 'singleton'

module DTK
  module CommandAndControlAdapter

    class StompMultiplexer < ProtocolMultiplexer
      include Singleton

      def self.create(stomp_client)
        instance.set(stomp_client)
      end

      def set(stomp_client)
        @stomp_client = stomp_client
        super(stomp_client)
      end

      def create_message(uuid, msg, agent, pbuilderid)
        msg.merge({
          request_id: uuid,
          pbuilderid: pbuilderid,
          agent: agent
        })
      end

      def self.process_response(msg, request_id)
        instance.process_response(msg, request_id)
      end

      def send_ping_request
        message = create_message(generate_request_id, {}, 'discovery', "/^(.*)$/")
        @stomp_client.publish(message)
      end

      def sendreq_with_callback(msg, agent, context_with_callbacks, filter = {})
        trigger = {
          generate_request_id: proc do |client|
            generate_request_id
          end,
          send_message: proc do |client, request_id|
            pbuilderid = filter['fact'].first[:value]

            message = create_message(request_id, msg, agent, pbuilderid)
            client.publish(message)
          end
        }

        process_request(trigger, context_with_callbacks)
      end

      private
      
      def generate_request_id
        ::MCollective::SSL.uuid.gsub("-", "")
      end

    end
  end
end
