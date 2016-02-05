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
require 'celluloid'
require 'redis'

module DTK
  class MessageQueue
    include Singleton

    attr_accessor :queue_internal

    def initialize
      @queue_internal = QueueInternal.new
    end

    def self.store(type, message)
      self.instance.queue_internal.async.store(message, CurrentSession.get_username(), type)
    end

    def self.retrive
      self.instance.queue_internal.retrive(CurrentSession.get_username())
    end
  end

  class QueueInternal
    include Celluloid

    # sets queue time to live - each time msg enter queue TTL is refreshed
    QUEUE_TTL = 60

    attr_accessor :queue_data

    def initialize
      @redis_queue = Redis.new
    end

    def store(message, session_username, type = :info)
      @redis_queue.lpush session_username, { message: message, type: type }.to_json
      @redis_queue.expire session_username, QUEUE_TTL
    end

    def retrive(session_username)
      messages = []
      msg      = @redis_queue.rpop(session_username)
      messages << JSON.parse(msg) if msg
      messages
    end
  end
end