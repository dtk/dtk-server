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
module DTK; class ModuleBranch
  class Location
    class Params < Hash
      # module_name, version, and namespace are common params for local and remote
      def module_name(opts = {})
        ret = self[:module_name]
        if opts[:with_namespace]
          unless ns = module_namespace_name()
            fail Error.new('Unexpected that self does not have namespace set')
          end
          ret = Namespace.join_namespace(ns, ret)
        end
        ret
      end

      def module_namespace_name
        self[:namespace]
      end

      def module_type
        self[:module_type]
      end

      def version
        self[:version]
      end

      def namespace
        self[:namespace]
      end

      def source_name
        self[:source_name]
      end

      def initialize(params)
        unless params.is_a?(self.class)
          validate(params)
        end
        replace(params)
      end

      def pp_module_name(_opts = {})
        ret = module_name
        if version
          ret << "(#{version})"
        end

        module_namespace_name ? "#{module_namespace_name}:#{ret}" : ret
      end

      private

      def validate(params)
        unless (bad_keys = params.keys - all_keys()).empty?
          fail Error.new("Illegal key(s): #{bad_keys.join(',')}")
        end
        missing_required = required_keys().select { |key| params[key].nil? }
        unless missing_required.empty?
          fail Error.new("Required key(s): #{missing_required.join(',')}")
        end
      end

      def all_keys
        legal_keys().map { |k| optional?(k) || k }
      end

      def required_keys
        legal_keys().reject { |k| optional?(k) }
      end

      def optional?(k)
        k = k.to_s
        if k =~ /\?$/
          k.gsub(/\?$/, '').to_sym
        end
      end
    end
  end
end; end