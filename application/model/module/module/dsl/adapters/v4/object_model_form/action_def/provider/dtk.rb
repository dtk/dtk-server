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
# TODO: Move from catch all provider dtk to individual ones
module DTK; class ModuleDSL; class V4; class ObjectModelForm
  class ActionDef; class Provider
    class Dtk < self
      module Constant
        module Variations
        end
        extend Aux::ParsingingHelper::ClassMixin

        Functions = 'functions'
        Variations::Functions = ['functions', 'function']

        Docker = 'docker'
        Variations::Docker = ['docker_image', 'docker_run_params', 'docker_file_template']

        DeleteNode = 'delete_node'
      end

      def initialize(input_hash, _opts = {})
        super(provider: type.to_s).merge!(provider_specific_fields(input_hash))
      end

      def self.type
        :dtk
      end

      def self.matches_input_hash?(input_hash)
        !!Constant.matches?(input_hash, :Functions) || !!Constant.matches?(input_hash, :Docker) || !!Constant.matches?(input_hash, :DeleteNode)
      end

      def external_ref_from_function
        if functions = self[:functions]
          type = functions.first.slice('type')
        end
      end

      def external_ref_from_docker
        { type: 'docker' }
      end

      def external_ref_from_delete_node
        { type: 'delete_node' }
      end


      private

      def provider_specific_fields(input_hash)
        ret =
          if functions = Constant.matches?(input_hash, :Functions)
            { functions: functions.is_a?(Array) ? functions : [functions] }
          elsif docker = Constant.matches?(input_hash, :Docker)
            # { docker: docker.is_a?(Array) ? docker : [docker] }
            { docker: [input_hash]}
          elsif delete_node = Constant.matches?(input_hash, :DeleteNode)
            # { docker: docker.is_a?(Array) ? docker : [docker] }
            { delete_node: [delete_node]}
          end

        stdout_err = input_hash['stdout_and_stderr']
        unless stdout_err.nil?
          fail ParsingError.new(':stdout_and_stderr has invalid value. Must be set to true or false') unless ['true', 'false'].include?(stdout_err.to_s)
          ret.merge!(stdout_and_stderr: stdout_err)
        end

        ret
      end

    end
  end; end
end; end; end; end
