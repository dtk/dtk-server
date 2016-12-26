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

      # opts can have keys
      #  :info_type - which could have value service_info or component_info
      def initialize(params, opts = {})
        unless params.is_a?(self.class)
          validate(params)
        end
        replace(info_type_substitution?(params, opts[:info_type]))
      end

      # module_name, version, and namespace are common params for local and remote
      def module_name(opts = {})
        ret = self[:module_name]
        if opts[:with_namespace]
          unless ns = module_namespace_name
            fail Error, 'Unexpected that self does not have namespace set'
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

      def pp_module_ref(_opts = {})
        ::DTK::Common::PrettyPrintForm.module_ref(module_name, namespace: module_namespace_name, version: version)
      end

      private

      def validate(params)
        unless (bad_keys = params.keys - all_keys).empty?
          fail Error, "Illegal key(s): #{bad_keys.join(',')}"
        end
        missing_required = required_keys.select { |key| params[key].nil? }
        unless missing_required.empty?
          fail Error, "Required key(s): #{missing_required.join(',')}"
        end
      end
      
      def info_type_substitution?(params, info_type)
        if info_type.nil? or params[:module_type] != self.class.combined_module_type
          params
        else
          ret = params.inject({}) { |h, (k, v)|k == :module_type ? h : h.merge(k => v) }
          if info_type == self.class.service_info_type
            ret.merge!(:module_type => :service_module)
          elsif info_type == self.class.component_info_type
            ret.merge!(:module_type => :component_module)
          else
            fail Error, "Illegal info_type '#{info_type}'"
          end
        end
      end

      def self.combined_module_type
        @combined_module_type ||= CommonModule.combined_module_type
      end
      def self.service_info_type
        @service_info_type ||= CommonModule::Info::Service.info_type
      end
      def self.component_info_type
        @component_info_type ||= CommonModule::Info::Component.info_type
      end

      def all_keys
        legal_keys.map { |k| optional?(k) || k }
      end

      def required_keys
        legal_keys.reject { |k| optional?(k) }
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
