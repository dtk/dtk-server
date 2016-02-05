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
  class HierarchicalTags < Hash
    def self.reify(obj)
      unless obj.nil?
        obj.is_a?(HierarchicalTags) ? obj : new(obj)
      end
    end
    def initialize(obj)
      super()
      replace_hash =
        if obj.is_a?(String)
          { obj.to_sym => nil }
        elsif obj.is_a?(Hash)
          obj.inject({}) { |h, (k, v)| h.merge(k.to_sym => v.is_a?(Hash) ? self.new(v) : v) }
        elsif obj.is_a?(Array) && !obj.find { |el| !el.is_a?(String) }
          obj.inject({}) { |h, k| h.merge(k.to_sym => nil) }
        else
          fail Error.new("Illegal input to form hierarchical hash (#{obj.inspect})")
        end
      replace(replace_hash)
    end

    def base_tags?
      ret = keys
      ret unless ret.empty?
    end

    def nested_tag_value?(base_tag)
      base_tag = normalize_key(base_tag)
      has_tag?(base_tag) && self[base_tag]
    end

    def has_tag?(base_tag)
      base_tag = normalize_key(base_tag)
      key?(base_tag)
    end

    private

     def normalize_base_tag(base_tag)
       base_tag.to_sym
     end
  end
end