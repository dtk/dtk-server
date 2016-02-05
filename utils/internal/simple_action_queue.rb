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
  # One dimensional queue to support much simpler needs for queing simpler results.
  # Unlike ActionResultQueue there is no need to support multiple results from different
  # nodes.
  class QueueNotFound < Error
    def initialize(queue_id, available_ids)
      super("Simple Action queue could not find queue with ID #{queue_id}, available queues [#{available_ids.join(',')}]")
    end

  end

  class SimpleActionQueue
    def self.get_results(queue_id)
      queue = self[queue_id]
      response_results = nil

      fail QueueNotFound.new(queue_id, self.available_ids) if queue.nil?

      unless queue.result.nil?
        response_results = queue.result
        delete(queue_id)
      end

      { result: response_results }
    end

    attr_accessor :id, :result

    Lock = Mutex.new
    Queues = {}
    @@count = 0

    def initialize
      Lock.synchronize do
        @@count += 1
        @id = @@count
        @result = nil
        Queues[@id] = self
      end
    end

    def self.delete(queue_id)
      Lock.synchronize do
        Queues.delete(queue_id.to_i)
      end
    end

    def self.[](queue_id)
      Queues[queue_id.to_i]
    end

    def self.available_ids
      Queues.keys
    end

    def set_result(el)
      # TODO: Rich: thik this is an error @result = el.data
      @result = el
    end
  end
end