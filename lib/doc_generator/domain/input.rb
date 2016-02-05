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
module DTK; class DocGenerator; class Domain
  class Input < ::Hash
    def initialize(hash = {})
      super()
      replace(hash) unless hash.empty?
    end

    # can return nil
    def scalar(key)
      value?(key)
    end

    # Always returns an Input object
    def hash(key)
      ret = Input.new
      return ret unless obj = value?(key)
      if obj.kind_of?(Hash)
        ret.merge!(obj) 
      end
      ret
    end

    def hash_or_scalar(key)
      ret = hash(key)
      if ret.empty?
        ret = scalar(key) 
      end
      ret
    end

    # Only reifies one level
    # Always returns an array
    def array(key)
      ret = []
      return ret unless obj = value?(key)

      if obj.kind_of?(Array)
        ret = obj.map { |el| reify_if_hash(el) }
      elsif obj.kind_of?(Hash)
        # if value is a hash then just return values part plus key becomes display_name
        ret = obj.map { |(k,v)| reify_if_hash(v, added_values: { 'display_name' => k }) }
      end
      ret
    end

    def self.raw_input(obj)
      new('raw' => obj)    
    end

    private

    def reify_if_hash(obj, opts = {})
      return obj unless obj.kind_of?(Hash)
      hash = obj
      if added_values = opts[:added_values]
        # existing values in hash take precedence over added_values
        hash = added_values.merge(hash)
      end
      self.class.new(hash)
    end

    def value?(key)
     if has_key?(key.to_s)
       self[key.to_s]
     elsif has_key?(key.to_sym)
       self[key.to_sym]
     end
    end
  end
end; end; end