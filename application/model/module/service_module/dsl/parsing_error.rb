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
  class ServiceModule
    class ParsingError < ErrorUsage::Parsing
      r8_nested_require('parsing_error', 'aggregate')
      r8_nested_require('parsing_error', 'dangling_component_refs')
      r8_nested_require('parsing_error', 'removed_service_instance_cmp_ref')
      r8_nested_require('parsing_error', 'bad_component_link')

      # These can be ovewritten; default is simple behavior that ignores new errors (reports first one)
      def add_with(aggregate_error = nil)
        aggregate_error || self
      end

      def add_error_opts(_error_opts = Opts.new)
        self
      end

      class BadNodeReference < self
        def initialize(params = {})
          err_msg = "Bad node template (?node_template) in assembly '?assembly'"
          err_params = Params.new(node_template: params[:node_template], assembly: params[:assembly])
          super(err_msg, err_params)
        end
      end

      class BadAssemblyReference < self
        def initialize(params = {})
          err_msg = "Assembly name (?name) does not match assembly name in file path '?file_path'"
          err_params = Params.new(file_path: params[:file_path], name: params[:name])
          super(err_msg, err_params)
        end
      end

      class BadNamespaceReference < self
        def initialize(params = {})
          err_msg = 'Namespace (?name) referenced in module_refs file does not exist in local environment'
          err_params = Params.new(name: params[:name])
          super(err_msg, err_params)
        end
      end

      class BadComponentReference < self
        def initialize(params = {})
          err_msg = "The following component template (?component_name) required by node (?node_name) is not referenced in #{ModuleRefs.meta_filename_path()} with its component module and namespace which it belongs to"
          err_params = Params.new(component_name: params[:component_name], node_name: params[:node_name])
          super(err_msg, err_params)
        end
      end

      class AmbiguousModuleRef < self
        def initialize(params = {})
          err_msg = 'Reference to ?module_type module (?module_name) is ambiguous; it belongs to the namespaces (?namespaces); one of these namespaces should be selected by editing the module_refs file'

          err_params = Params.new(
            module_type: params[:module_type],
            module_name: params[:module_name],
            namespaces: params[:namespaces].join(',')
          )
          super(err_msg, err_params)
        end
      end
    end
  end
end