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
module DTK; class Node; class TargetRef
  class Input; class InventoryData
    #TODO: this is just temp until move from client formating data; right now hash is of form
    # {"physical--install-agent1"=>
    #  {"display_name"=>"install-agent1",
    #   "os_type"=>"ubuntu",
    # "managed"=>"false",
    # "external_ref"=>
    class Element < Hash
      def initialize(ref, hash)
        super()
        if ref =~ Regexp.new("^#{TargetRef.physical_node_prefix()}")
          replace(hash)
          @type = :physical
        else
          fail Error.new("Unexpected ref for inventory data ref: #{ref}")
        end
      end

      def target_ref_hash
        unless name = self['name'] || self['display_name']
          fail Error.new("Unexpected that that element (#{inspect}) has no name field")
        end
        ret_hash = merge('display_name' => ret_display_name(name))

        external_ref = self['external_ref'] || {}
        ret_hash.merge!(type: external_ref['type'] || Type::Node.target_ref)

        host_address = nil
        if @type == :physical
          unless host_address = external_ref['routable_host_address']
            fail Error.new("Missing field input_node_hash['external_ref']['routable_host_address']")
          end
        end
        params = { 'host_address' => host_address }
        ret_hash.merge!(Input.child_objects(params))
        { ret_ref(name) => ret_hash }
      end

      private

      def ret_display_name(name)
        TargetRef.ret_display_name(@type, name)
      end

      def ret_ref(name)
        "#{@type}--#{name}"
      end
    end
  end; end
end; end; end