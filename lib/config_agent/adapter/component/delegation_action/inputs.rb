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
  class ConfigAgent::Adapter::Component::DelegationAction
    class Inputs
      def initialize(input_spec, base_input_values)
        @input_spec        = input_spec
        @base_input_values = base_input_values
      end
      private :initialize

      def self.bind(input_spec, base_input_values)
        new(input_spec, base_input_values).bind
      end
   
      def bind
      end

      protected
      
      attr_reader :input_spec, :base_input_values
      
    end
  end
end
