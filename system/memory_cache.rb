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
require 'memcache'

# TBD: may have a set of these that are in different namespaces
module XYZ
  class MemoryCache
    class << self
      @@cache = nil
      def set_cache_servers(server_list)
        #TBD: hard wired port
        if server_list.empty?
    @@cache = nil
          return nil
        end
        @@cache = MemCache.new(server_list.map { |s| s + ':11211' })
      end

      def set(key, value)
        @@cache.set(key, value) unless  @@cache.nil?
      end

      def get(key)
        @@cache ? @@cache.get(key) : nil
      end
    end
  end
end