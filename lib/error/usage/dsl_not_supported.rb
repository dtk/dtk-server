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
  class DSLNotSupported < ErrorUsage::Parsing
    def component_print_form(component_type, context = {})
      ret = Component.component_type_print_form(component_type)
      if title = context[:title]
        ret = ComponentTitle.print_form_with_title(ret, title)
      end
      if node_name = context[:node_name]
        ret = "#{node_name}/#{ret}"
      end
      ret
    end

    class LinkToNonComponent < self
      def initialize(opts = {})
        fail ErrorUsage.new('Only supported: Attribute linked to a component attribute', Opts.new(opts).slice(:file_path))
      end
    end

    class LinkBetweenSameComponentTypes < self
      def initialize(cmp_instance, opts = {})
        super(base_msg(cmp_instance), Opts.new(opts).slice(:file_path))
      end

      private

      def base_msg(cmp_instance)
        cmp_type_print_form = cmp_instance.component_type_print_form()
        fail ErrorUsage.new("Not supported: Attribute link involving same component type (#{cmp_type_print_form})")
      end
    end
  end
end