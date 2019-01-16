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
  class ModuleDSL::V4::ObjectModelForm::ActionDef::Provider
    class Workflow < self
      module Constant
        module Variations
        end
        extend Aux::ParsingingHelper::ClassMixin
        Workflow = 'workflow'
        Type = 'type'
      end
      
      def initialize(input_hash, opts = {})
        @input_hash           = input_hash
        @providers_input_hash = opts[:providers_input_hash] || {}
        @action_name          = opts[:action_name]
        @cmp_print_form       = opts[:cmp_print_form]

        super(provider: type.to_s).merge!(provider_specific_fields)
      end

      def self.type
        :workflow
      end

      def self.matches_input_hash?(input_hash)
        !!Constant.matches?(input_hash, :Workflow) && !!Constant.matches?(input_hash, :Type)
      end

      private

      def provider_specific_fields()
        @input_hash
      end

    end
  end
end

