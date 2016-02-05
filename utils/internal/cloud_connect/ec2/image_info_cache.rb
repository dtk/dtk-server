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
module DTK; class CloudConnect
  class EC2
    class ImageInfoCache
      def initialize(type, conn)
        @type       = type
        @cache_info = cache_info(type, conn)
      end

      def self.get_or_set(type, conn, image_id, opts = {}, &block)
        new(type, conn).get_or_set(image_id, opts, &block)
      end

      MutexPerType = {}
      def get_or_set(image_id, opts = {}, &block)
        if opts[:mutex]
          lock = MutexPerType[@type] ||= Mutex.new
          lock.synchronize do 
            get_or_set_direct_call(image_id, &block)
          end
        else
          get_or_set_direct_call(image_id, &block)
        end
      end

      private

      Cache = {
        image_get: {}
      }

      def cache_info(type, _conn)
        Cache[type] || fail(Error.new("Caching of type '#{type}' not supported"))
      end

      def get_or_set_direct_call(image_id, &block)
        get?(image_id) || set(image_id, &block)
      end

      def get?(image_id)
        if ret = @cache_info[image_id]
          Log.info("Using image cache for #{@type}: image '#{image_id}'; thread '#{Aux.thread_id}'")
          ret
        end
      end
        
      def set(image_id, &block)
        Log.info("Setting image cache for #{@type}: image '#{image_id}'; thread '#{Aux.thread_id}'")
        @cache_info[image_id] = yield
      end
    end
  end
end; end