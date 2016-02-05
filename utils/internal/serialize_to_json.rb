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
require 'active_support/ordered_hash'
require 'json'
module XYZ
  class SerializeToJSON
    def self.serialize(obj)
      return obj unless obj.is_a?(Hash) || obj.is_a?(Array)
      ordered_obj = ret_ordered_object(obj)
      ordered_obj.to_json
    end

    private

    def self.ret_ordered_object(obj)
      # Hashes for Ruby 1.9.x are sorted already; so no-op for tehse
      return obj if RUBY_VERSION =~ /^1\.9\./

      return obj unless obj.is_a?(Hash) || obj.is_a?(Array)
      if obj.is_a?(Array)
        obj.map { |x| ret_ordered_object(x) }
      else
        ordered_hash = ActiveSupport::OrderedHash.new()
        sorted_keys(obj.keys).each { |key| ordered_hash[key] = ret_ordered_object(obj[key]) }
        ordered_hash
      end
    end
    def self.sorted_keys(keys)
      keys.sort { |a, b| a.to_s <=> b.to_s }
    end
  end
end