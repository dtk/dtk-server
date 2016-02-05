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
module DTK; class Clone; class IncrementalUpdate
  module InstancesTemplates
    class Link
      attr_reader :instances, :templates, :parent_link
      def initialize(instances, templates, parent_link)
        @instances = instances
        @templates = templates
        @parent_link = parent_link
      end

      def instance_model_handle
        # want parent information
        @parent_link.instance.child_model_handle(instance_model_name())
      end

      private

      def instance_model_name
        #all templates and instances should have same model name so just need to find one
        #one of these wil be non null
        (@instances.first || @templates.first).model_name
      end
    end
  end
end; end; end