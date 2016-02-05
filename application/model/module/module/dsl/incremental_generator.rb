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
module DTK; class ModuleDSL
  class IncrementalGenerator
    def self.generate(aug_object)
      klass(aug_object).new().generate(ObjectWrapper.new(aug_object))
    end

    def self.merge_fragment_into_full_hash!(full_hash, object_class, fragment, context = {})
      klass(object_class).new().merge_fragment!(full_hash, fragment, context)
      full_hash
    end

    private

    def self.klass(object_or_class)
      klass = (object_or_class.is_a?(Class) ? object_or_class : object_or_class.class)
      class_last_part = klass.to_s.split('::').last
      ret = nil
      begin
        ret = const_get class_last_part
       rescue
        raise Error.new("Generation of type (#{class_last_part}) not treated")
      end
      ret
    end

    def set?(key, content, obj)
      val = obj[key]
      unless val.nil?
        content[key.to_s] = val
      end
    end

    def component_fragment(full_hash, component_template)
      unless component_type = component_template && component_template.get_field?(:component_type)
        fail Error.new('The method merge_fragment needs the context :component_template')
      end
      component().get_fragment(full_hash, component_type)
    end

    class ObjectWrapper
      attr_reader :object
      def initialize(object)
        @object = object
      end

      def required(key)
        ret = @object[key]
        if ret.nil?
          fail Error.new("Expected that object of type (#{@object}) has non null key (#{key})")
        end
        ret
      end

      def [](key)
        @object[key]
      end
    end
  end
end; end