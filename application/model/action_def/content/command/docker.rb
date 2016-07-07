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
module DTK; class ActionDef; class Content
  class Command
    class Docker < self
      attr_reader :docker_image, :docker_file_template, :docker_run_params, :entrypoint

      def initialize(docker_image, docker_file_template, docker_run_params, entrypoint)
        @docker_image         = docker_image
        @docker_file_template = docker_file_template
        @docker_run_params    = docker_run_params
        @entrypoint           = entrypoint
      end

      def self.parse?(serialized_command)
        if serialized_command.is_a?(Hash) && (serialized_command.key?(:docker_image) || serialized_command.key?(:docker_file_template) || serialized_command.key?(:docker_run_params))
          new(serialized_command[:docker_image], serialized_command[:docker_file_template], serialized_command[:docker_run_params], serialized_command[:entrypoint])
        end
      end

      def type
        'docker'
      end
    end
  end
end; end; end