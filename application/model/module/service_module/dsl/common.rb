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
  module ServiceDSLCommonMixin
    Seperators = {
      module_component: '::', #TODO: if this changes need to change ModCompGsub
      component_version: ':',
      component_port: '/',
      assembly_node: '/',
      node_component: '/',
      component_link_def_ref: '/',
      title_before: '[',
      title_after: ']'
    }
    ModCompInternalSep = '__' #TODO: if this changes need to chage ModCompGsub[:sub]
    ModCompGsub = {
      pattern: /(^[^:]+)::/,
      sub: '\1__'
    }
    CmpVersionRegexp = Regexp.new("(^.+)#{Seperators[:component_version]}([0-9]+.+$)")

    # pattern that appears in dsl that designates a component title
    DSLComponentTitleRegex = /(^.+)\[(.+)\]/

    module InternalForm
      def self.component_ref(cmp_type_ext_form)
        cmp_type_ext_form.gsub(ModCompGsub[:pattern], ModCompGsub[:sub])
      end

      # returns hash with keys
      # component_type,
      # version (optional)
      # title (optional)
      def self.component_ref_info(cmp_type_ext_form)
        ref = component_ref(cmp_type_ext_form)
        if ref =~ CmpVersionRegexp
          type = Regexp.last_match(1); version = Regexp.last_match(2)
        else
          type = ref; version = nil
        end
        if type =~ DSLComponentTitleRegex
          type = Regexp.last_match(1)
          title = Regexp.last_match(2)
          ref = ComponentTitle.ref_with_title(type, title)
          display_name = ComponentTitle.display_name_with_title(type, title)
        end
        ret = { component_type: type }
        ret.merge!(version: version) if version
        ret.merge!(title: title) if title
        ret
      end
    end
  end
end