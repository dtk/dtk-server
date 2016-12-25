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
module DTK; class ModuleDSL; class V4; class ObjectModelForm
  class ActionDef; class Provider
    class Puppet < self
      module Constant
        module Variations
        end
        extend Aux::ParsingingHelper::ClassMixin

        PuppetClass = 'puppet_class'
        PuppetDefinition = 'puppet_definition'
      end

      def initialize(input_hash, _opts = {})
        @provider_specific_fields = provider_specific_fields(input_hash)
        super(provider: type.to_s).merge!(@provider_specific_fields)
      end

      def self.type
        :puppet
      end

      AllKeys = [:PuppetClass, :PuppetDefinition]

      def self.matches_input_hash?(input_hash)
        !!AllKeys.find { |k| Constant.matches?(input_hash, k) }
      end

      def provider_specific_fields(input_hash)
        input_hash ||= self
        AllKeys.inject({}) do |h, k|
          h.merge(Constant.matching_key_and_value?(input_hash, k) || {})
        end
      end

      def external_ref_from_create_action
        @provider_specific_fields
      end
    end
  end; end
end; end; end; end
