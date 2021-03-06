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
  class Opts < Hash
    # if ?foo means include if not null
    def self.create?(initial_val)
      new(convert_for_create?(initial_val))
    end
    def initialize(initial_val = nil)
      super()
      if initial_val
        # add if non null; doing 'deep check for nil'
        initial_val.each_pair do |k, v|
          processed_v = remove_nested_nil(v)
          merge!(k => processed_v) unless processed_v.nil?
        end
      end
    end

    def merge?(hash)
      hash.each_pair { |k, v| merge!(k => v) unless v.nil? }
    end

    def slice(*keys)
      keys.inject(self.class.new) do |h, k|
        v = self[k]
        (v.nil? ? h : h.merge(k => v))
      end
    end

    def array(key)
      self[key] || []
    end

    def required(key)
      val  = self[key]
      if val.nil?
        fail Error.new("Key (#{key}) is required as an option")
      end
      val
    end

    def add_value_to_return!(key)
      (self[:return_values] ||= ReturnValue.new).add_value_to_return!(key)
    end

    def return_value(key)
      if rvs = self[:return_values]
        rvs[key]
      end
    end

    def set_return_value!(key, val)
      if rvs = self[:return_values]
        if rvs.key?(key)
          rvs[key] = val
        end
      end
      self
    end

    def set_datatype!(val)
      set_return_value!(DatatypeKey, val)
    end

    def get_datatype
      return_value(DatatypeKey)
    end

    def add_return_datatype!
      add_value_to_return!(DatatypeKey)
      self
    end
    DatatypeKey = :datatype

    private

    def self.convert_for_create?(raw)
      raw.inject({}) do |h, (k, v)|
        if non_null_var = is_only_non_null_var?(k)
          v.nil? ? h : h.merge(non_null_var => v)
        else
          h.merge(k => v)
        end
      end
    end
    def self.is_only_non_null_var?(k)
      if k.to_s =~ /\?$/
        k.to_s.gsub(/\?$/, '').to_sym
      end
    end

    def remove_nested_nil(val)
      unless val.class == Hash #using this test rather than val.kind_of?(Hash) because only want to match on Hash and not its children classes
        val
      else
        val.inject({}) do |h, (k, child_v)|
          if processed_val = remove_nested_nil(child_v)
            h.merge(k => processed_val)
          else
            h
          end
        end
      end
    end

    class ReturnValue < Hash
      def add_value_to_return!(key)
        self[key] ||= nil
      end
    end
  end
end
