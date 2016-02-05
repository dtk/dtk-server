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
  class HashObject
    class Model < self
      def nested_value(*path)
        return self if path.empty?
        self.class.nested_value_private!(self, path.dup)
      end

      class << self
        def [](x)
          new(x)
        end

        def nested_value(hash, path)
          return hash if path.empty?
          nested_value_private!(hash, path.dup)
        end

        def has_path?(hash, path)
          return true if path.empty?
          has_path_private!(hash, path.dup)
        end

        def set_nested_value!(hash, path, val)
          if path.size == 0
            # TODO: this should be error
          elsif path.size == 1
            hash[path.first] = val
          else
            hash[path.first] ||= {}
            set_nested_value!(hash[path.first], path[1..path.size - 1], val)
          end
        end
      end

      private

      # "*" in path means just take whatever is next (assuming singleton; otehrwise takes first
      # marked by "!" since it updates the path parameter
      def self.nested_value_private!(hash, path)
        return nil unless hash.is_a?(Hash)
        f = path.shift
        f = hash.keys.first if f == '*'
        return nil unless hash.key?(f)
        return hash[f] if path.length == 0
        nested_value_private!(hash[f], path)
      end
      def self.has_path_private!(hash, path)
        return nil unless hash.is_a?(Hash)
        f = path.shift
        f = hash.keys.first if f == '*'
        return nil unless hash.key?(f)
        return hash.key?(f) if path.length == 0
        nested_value_private!(hash[f], path)
      end
    end
  end
end