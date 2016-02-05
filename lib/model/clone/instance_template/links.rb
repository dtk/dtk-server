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
module DTK; class Clone
  module InstanceTemplate
    class Links < Array
      def add(instance, template)
        self << Link.new(instance, template)
      end

      def parent_rels(child_mh)
        parent_id_col = child_mh.parent_id_field_name()
        map { |link| { parent_id_col => link.instance.id, :old_par_id => link.template.id } }
      end

      def template(instance)
        match = match_instance(instance)
        match[:template] || fail(Error.new("Cannot find matching template for instance (#{instance.inspect})"))
      end

      def match_instance(instance)
        instance_id = instance.id
        unless match = find { |l| l.instance && l.instance.id == instance_id }
          fail(Error.new("Cannot find match for instance (#{instance.inspect})"))
        end
        match
      end

      def all_id_handles
        templates().map(&:id_handle) + instances().map(&:id_handle)
      end

      def templates
        #removes dups
        inject({}) do |h, l|
          template = l.template
          h.merge(template ? { template.id => template } : {})
        end.values
      end

      def instances
        #does not have dups
        map(&:instance).compact
      end
    end
  end
end; end