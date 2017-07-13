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
 class ModuleDSL
    class ParsingError < ErrorUsage::Parsing
      require_relative('parsing_error/ref_component_templates')
      require_relative('parsing_error/location')
      require_relative('parsing_error/dependency')
      require_relative('parsing_error/missing_key')
      require_relative('parsing_error/illegal_keys')

      def initialize(msg = '', *args_x)
        args = Params.add_opts(args_x, error_prefix: ErrorPrefix, caller_info: true)
        super(msg, *args)
      end
      ErrorPrefix = 'Component dsl parsing error'

      class MissingFromModuleRefs < self
        def initialize(params = {})
          missing_modules = params[:modules]
          what = (missing_modules.size == 1 ? 'component module' : 'component modules')
          is   = (missing_modules.size == 1 ? 'is' : 'are')
          does = (missing_modules.size == 1 ? 'does' : 'do')
          refs = missing_modules.join(',')

          err_msg = "The following #{what} (#{refs}) that #{is} referenced in includes section #{does} not exist in module refs file; this can be rectified by invoking the 'push' command after manually adding appropriate component module(s) to module refs file or by removing references in the DSL file(s)"
          # err_msg = "Component module(s) (?name) referenced in includes section are not specified in module refs file"
          err_params = Params.new(modules: params[:modules].join(','))
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

      class BadPuppetDefinition < self
        def initialize(params = {})
          component = params[:component]
          invalid_names = params[:invalid_names]
          # missing_req_or_def = params[:missing_req_or_def]

          if invalid_names
            err_msg =
              (invalid_names.size == 0) ? 'The following component (?name) that is mapped to puppet definition does not have designated name attribute' : 'The following component (?name) that is mapped to puppet definition has multiple attributes designated as being the puppet definition name'
            # elsif missing_req_or_def
            # err_msg = "The following component (?name) that is mapped to puppet definition has name attribute that is not marked as required or does not have default value"
          end

          err_params = Params.new(name: params[:component])
          super(err_msg, err_params)
        end
      end

       class BadPortNumber < self
        def initialize(params = {})
          component = params[:component]
          invalid_names = params[:invalid_names]
          err_msg = 'The following port (?name) is invalid'
          
          err_params = Params.new(name: params[:component])
          super(err_msg, err_params)
        end
      end


      class AmbiguousModuleRef < self
        def initialize(params = {})
          err_msg = 'Reference to module (?module_name) is ambiguous; it belongs to the namespaces (?namespaces); one of these namespaces should be selected and added to the dependencies section'

          err_params = Params.new(
            module_type: params[:module_type],
            module_name: params[:module_name],
            namespaces: params[:namespaces].join(', ')
          )
          super(err_msg, err_params)
        end
      end
    end
  end
end
