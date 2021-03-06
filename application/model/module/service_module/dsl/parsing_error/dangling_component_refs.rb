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
module DTK; class ServiceModule
  class ParsingError
    class DanglingComponentRefs < self
      attr_reader :cmp_ref_info_list
      def initialize(cmp_ref_info_list, opts = {})
        super(err_msg(cmp_ref_info_list), opts)
        # each element can be a component ref object or a hash
        @cmp_ref_info_list = cmp_ref_info_list
      end

      def add_error_opts(error_opts = {})
        error_opts.empty? ? self : self.class.new(@cmp_ref_info_list, error_opts)
      end

      #
      # Returns list of missing modules with version
      #
      def missing_module_list
        # forming hash and then getting its vals to remove dups in same <module,version,namepsace>
        module_hash = @cmp_ref_info_list.inject({}) do |h, r|
          module_name = r[:component_type].split('__').first
          remote_namespace = r[:remote_namespace]
          ndx = "#{module_name}---#{r[:version]}---#{remote_namespace}"
          info = {
            name: module_name,
            version: r[:version]
          }
          info.merge!(remote_namespace: remote_namespace) if remote_namespace
          h.merge!(ndx => info)
        end

        module_hash.values
      end

      # aggregate_error can be nil, a anglingComponentRefs error or other error
      def add_with(aggregate_error = nil)
        if aggregate_error.nil?
          self
        elsif aggregate_error.is_a?(DanglingComponentRefs)
          self.class.new(ret_unique_union(@cmp_ref_info_list, aggregate_error.cmp_ref_info_list))
        else
          super
        end
      end

      private

      def ret_unique_union(cmp_refs1, cmp_refs2)
        ndx_ret = cmp_refs1.inject({}) { |h, r| h.merge(ret_unique_union__ndx(r) => r) }
        cmp_refs2.inject(ndx_ret) { |h, r| h.merge(ret_unique_union__ndx(r) => r) }.values
      end

      def ret_unique_union__ndx(cmp_ref_info)
        ret = cmp_ref_info[:component_type]
        if version = cmp_ref_info[:version]
          ret = "#{ret}(#{version})"
        end
        ret
      end

      def err_msg(cmp_ref_info_list)
        components, are = (cmp_ref_info_list.size == 1 ? ['component', 'is'] : ['components', 'are'])
        refs = cmp_ref_info_list.map { |cmp_ref_info| ComponentRef.print_form(cmp_ref_info) }.compact.join(', ')

        "The #{components} (#{refs}) that #{are} referenced by the assembly #{are} not installed"
      end
    end
  end
end; end
