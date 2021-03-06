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
require 'erubis'
module DTK; class ServiceSetting
  class AttributeSettings
    class Element
      attr_reader :raw_value
      def initialize(attribute_path, raw_value)
        @attribute_path = attribute_path
        @raw_value = raw_value
      end

      def bind_parameters!(hash_params)
        # TODO: need alot more checking also making sure no unbound attribute
        ret = self
        unless @raw_value.is_a?(String)
          return ret
        end
        eruby =  ::Erubis::Eruby.new(@raw_value)
        begin
          @raw_value = eruby.result(hash_params)
         rescue Exception => e
          Log.error("The following erubis error resulted from service setting bindings: #{e.inspect}")
          params_print = hash_params.inject('') do |s, (k, v)|
            av = "#{k}=>#{v}"
            s.empty? ? av : "#{s},#{av}"
          end
          raise ErrorUsage.new("Error in applying setting parameters (#{params_print}) to attribute (#{@attribute_path}) with value (#{@raw_value}")
        end
        ret
      end

      def av_pair_form
        { pattern: @attribute_path, value: value() }
      end

      def value
        RawValue.value(@raw_value)
      end

      def equal_value?(el)
        RawValue.equal?(@raw_value, el.raw_value)
      end

      def unique_index
        @attribute_path
      end

      module RawValue
        def self.value(val)
          (val.nil? or val.is_a?(::Hash) or val.is_a?(::Array)) ? val : val.to_s
        end

        def self.equal?(val1, val2)
          unless val1.class == val2.class
            return false
          end
          if val1.is_a?(::Hash)
            return false unless Aux.equal_sets(val1.keys, val2.keys)
            val1.each_pair do |key, val_val1|
              return false unless equal?(val_val1, val2[key])
            end
            true
          elsif val1.is_a?(::Array)
            return false unless val1.size == val2.size
            val1.each_with_index do |el_val1, i|
              return false unless equal?(el_val1, val2[i])
            end
            true
          else
            val1 == val2
          end
        end
      end
    end
  end
end; end