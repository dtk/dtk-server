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
  module Utils
    module MethodLogger
      def self.extended(base)
        clazz_methods = base.methods(false)

        base.class_eval do
          clazz_methods.each do |method_name|
            original_method = method(method_name).unbind
            define_singleton_method(method_name) do |*args, &block|
              puts "$$---> #{base}##{method_name}(#{args.inspect})"
              return_value = original_method.bind(self).call(*args, &block)
              puts "<---$$ #{base}##{method_name} #=> #{return_value.inspect}"
              return_value
            end
          end
        end
      end

      def self.included(base)
        methods = base.instance_methods(false) + base.private_instance_methods(false)

        base.class_eval do
          methods.each do |method_name|
            original_method = instance_method(method_name)
            define_method(method_name) do |*args, &block|
              puts "$$---> #{base}.instance##{method_name}(#{args.inspect})"
              return_value = original_method.bind(self).call(*args, &block)
              puts "<---$$ #{base}.instance##{method_name} #=> #{return_value.inspect}"
              return_value
            end
          end
        end
      end
    end
  end
end