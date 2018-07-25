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
module DTK; class ModuleDSL; class V4
  class ObjectModelForm
    class Component < OMFBase::Component
      module Constant
        module Variations
        end
        extend Aux::ParsingingHelper::ClassMixin
        Providers = 'providers'
      end

      private

      def body(input_hash, component_name, context = {})
        ret = OutputHash.new
        unless input_hash
          err_msg = "Missing definition for component '?1'"
          fail ParsingError.new(err_msg, component_print_form(component_name))
        end
        component_type = ret['display_name'] = ret['component_type'] = qualified_component(component_name)
        # version below refers to component brranch version not metafile version
        ret['version']    = ::DTK::Component.default_version
        ret['basic_type'] = 'service'
        ret.set_if_not_nil('description', input_hash['description'])
        add_attributes!(ret, component_type, input_hash)
        opts = {}
        add_dependent_components!(ret, input_hash, component_type, opts)
        ret.set_if_not_nil('component_include_module', include_modules?(input_hash, component_type, context))
        if opts[:constants]
          add_attributes!(ret, component_type, ret_input_hash_with_constants(opts[:constants]), constant_attribute: true)
        end

        ActionDef.set_action_info!(ret, input_hash, component_name, providers_input_hash: Constant.matches?(input_hash, :Providers))

        ret.set_if_not_nil('only_one_per_node', only_one_per_node(input_hash, ret['external_ref']))

        ret
      end

      def only_one_per_node(input_hash, external_ref)
        # if only_one_per_node is explicily or singleton are given then use this value
        ret = input_hash['only_one_per_node'] || input_hash['singleton']
        return ret unless ret.nil?
        
        # otherwise default is to make only_one_per_node true unless external_ref['type'] is set to 'puppet_definition'
        (external_ref || {})['type'] != 'puppet_definition'
      end

    end
  end
end; end; end
