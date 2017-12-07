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


require File.expand_path('../../../protocol_multiplexer', File.dirname(__FILE__))
require File.expand_path('../../../../ssh_cipher', File.dirname(__FILE__))

module DTK
  module CommandAndControlAdapter

    class StompMultiplexer < ProtocolMultiplexer
      include Singleton

      # this map is used to keep track of sent / received requirst_ids
      @@callback_registry = {}
      @@callback_heartbeat_registry = {}

      HeartbeatLock = Mutex.new

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

      def register_with_heartbeat_listener(pbuilderid, request_id)
        HeartbeatLock.synchronize do
          @@callback_heartbeat_registry[pbuilderid] = request_id
          Log.debug("Stomp heartbeat message with pbuilderid '#{pbuilderid}' has been registered to request id '#{request_id}'. Waiting for callback.")
        end
      end

      def register_with_listener(request_id, callbacks)
        @@callback_registry[request_id] = callbacks
        Log.debug("Stomp message ID '#{request_id}' has been registered! Waiting for callback.")
      end

      def self.process_response(msg, request_id)
        instance.process_response(msg, request_id)
      end

      def self.callback_registry
        @@callback_registry
      end

      def self.heartbeat_registry_entry(pbuilder_id)
        HeartbeatLock.synchronize do
          @@callback_heartbeat_registry.delete(pbuilder_id)
        end
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
          send_message: proc do |client, reqid|
            pbuilderid = filter['fact'].first[:value]

            message = create_message(reqid, msg, agent, pbuilderid)

            Log.info("Sending message with session id '#{client.ret_client.connection_frame.headers["session"]}'") if client.ret_client
            # when heartbeat signal comes trough we need to map it to existing request id
            register_with_heartbeat_listener(pbuilderid, reqid) if 'discovery'.eql?(agent)

            register_with_listener(reqid, Callbacks.create(context_with_callbacks[:callbacks]))
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