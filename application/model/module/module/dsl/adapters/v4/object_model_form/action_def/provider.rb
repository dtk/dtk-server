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
  class ActionDef
    class Provider < OutputHash
      require_relative('provider/dynamic')
      require_relative('provider/bash_commands')
      # TODO: DTK-2805:  cleanup provider/dtk since artifical catchall 
      require_relative('provider/dtk')
      require_relative('provider/puppet')


      # opts can have:
      #  :providers_input_hash: 
      #  :action_name: 
      #  :cmp_print_form
      def self.create(input_hash, opts = {})
        action_name = opts[:action_name]
        cmp_print_form = opts[:cmp_print_form]
        unless input_hash.is_a?(Hash)
          err_msg = "The following action definition on component '?1' is ill-formed: ?2"
          fail ParsingError.new(err_msg, cmp_print_form, action_name => input_hash)
        end
        provider_type = provider_type(input_hash, opts)
        unless provider_class = provider_type_to_class?(provider_type)
          err_msg = "The action '?1' on component '?2' has illegal provider type: ?3"
          fail ParsingError.new(err_msg, action_name, cmp_print_form, provider_type)
        end
        provider_class.new(input_hash, opts)
      end

      private

      def type
        self.class.type
      end

      # Dynamic must be last because it is catchall
      PROVIDER_CLASSES = [Dtk, Puppet, BashCommands] + [Dynamic]
      PROVIDER_TYPE_TO_CLASS = PROVIDER_CLASSES.inject({}) { |h, klass| h.merge(klass.send(:type) => klass) }

      def self.provider_type_to_class?(provider_type)
        PROVIDER_TYPE_TO_CLASS[provider_type.to_sym]
      end

      def self.provider_type(input_hash, opts = {})
        Constant.matches?(input_hash, :Provider) || compute_provider_type(input_hash, opts)
      end

      def self.compute_provider_type(input_hash, opts = {})
        ret = 
          if provider_class = PROVIDER_TYPE_TO_CLASS.find { |_provider, klass| klass.matches_input_hash?(input_hash) }
            provider_class[0]
          else
            Dynamic.matches_input_hash?(input_hash) && Dynamic.type
          end

        unless ret
          action_name = opts[:action_name]
          cmp_print_form = opts[:cmp_print_form]
          err_msg = "Cannot determine provider type associated with the action '?1' on component '?2'"
          fail ParsingError.new(err_msg, action_name, cmp_print_form)
        end
        ret
      end
    end
  end
end; end; end; end
