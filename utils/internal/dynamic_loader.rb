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
  # TODO: move all dynamic loading to use these helper classes
  class DynamicLoader
    def self.load_and_return_adapter_class(adapter_type, adapter_name, opts = {})
      caller_dir = caller.first.gsub(/\/[^\/]+$/, '')
      Lock.synchronize { r8_nested_require_with_caller_dir(caller_dir, "#{adapter_type}/adapters", adapter_name) }
      type_part = convert?(adapter_type, :adapter_type, opts)
      name_part = convert?(adapter_name, :adapter_name, opts)
      base_class = opts[:base_class] || DTK
      if opts[:subclass_adapter_name]
        base_class.const_get(type_part).const_get name_part
      else
        base_class.const_get "#{type_part}#{name_part}"
      end
     rescue LoadError
      raise Error.new("cannot find #{adapter_type} adapter (#{adapter_name})")
    end

    private

    Lock = Mutex.new
    def self.convert?(n, type, opts)
      (opts[:class_name] || {})[type] || cap_form(n)
    end

    def self.cap_form(x)
      x.to_s.split('_').map(&:capitalize).join('')
    end
  end
end