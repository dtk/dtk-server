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
  class CommonDSL::Diff
    class Element
      require_relative('element/modify')
      require_relative('element/add')
      require_relative('element/delete')

      attr_reader :qualified_key, :service_instance
      # opts can have keys:
      #   :service_instance
      def initialize(qualified_key, opts = {})
        @qualified_key    = qualified_key
        @service_instance =  opts[:service_instance]
      end

      def process(_result, _opts = {})
        fail Error::NoMethodForConcreteClass.new(self.class)
      end

      private

      def name
        relative_distinguished_name
      end

      def relative_distinguished_name
        @qualified_key.relative_distinguished_name
      end

      def assembly_instance
        (@service_instance && @service_instance.assembly_instance) || fail(Error, "Unexpected that @service_instance is nil") 
      end

      def project
        @project ||= assembly_instance.get_target.get_project
      end

    end
  end
end
