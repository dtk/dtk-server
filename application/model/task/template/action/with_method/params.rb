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
module DTK; class Task::Template; class Action::WithMethod
  class Params < ::Hash
    # Returns a Params object which is an attribute - value hash
    def self.parse(serialized_item)
      ret = Params.new
      attr_val_array = serialized_item.split(',').map { |attr_val| parse_attribute_value_pair?(attr_val) }.compact

      # check for dups and convert to attribute value hash
      count = {}
      attr_val_array.each do |attr_val|
        name, value = attr_val
        count[name] ||= 0
        count[name] += 1
        ret.merge!(name => value)
      end
      if count.values.find { |v| v > 1 }
        fail ParsingError, "The same parameter is assigned multiple times in: #{serialized_item}"
      end
      ret
    end
    
    private
    
    # returns [attr_name, attr_value]
    def self.parse_attribute_value_pair?(attr_val)
      return nil if attr_val.empty?

      unless attr_val =~ /(^[^=]+)=([^=]+$)/
        fail ParsingError, "The parameter assignment (#{attr_val}) is ill-formed"
      end

      name = remove_preceding_and_trailing_spaces(Regexp.last_match(1))
      value = remove_preceding_and_trailing_spaces(Regexp.last_match(2))
      [name, value]
    end

    def self.remove_preceding_and_trailing_spaces(str)
      str.gsub(/^[ ]+/,'').gsub(/[ ]+$/,'')
    end
  end
end; end; end