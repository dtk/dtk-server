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
  class Node
    class ExternalRef
      module Mixin
        def update_external_ref_field(ext_ref_field, val)
          update_hash_key(:external_ref, ext_ref_field, val)
        end

        def refresh_external_ref!
          self.delete(:external_ref)
          get_field?(:external_ref)
        end

        def external_ref
          ExternalRef.new(self)
        end
      end

      attr_reader :hash
      def initialize(node)
        @node = node
        @hash = @node.get_field?(:external_ref) || {}
      end

      def created?
        # TODO: this is hard coded to EC2 convention where thereis a field :instance_id
        !@hash[:instance_id].nil?
      end

      def dns_name?()
        @hash[:dns_name]
      end
      
      def references_image?(target)
        CommandAndControl.references_image?(target, hash())
      end
    end
  end
end