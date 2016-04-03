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
module DTK; module CommandAndControlAdapter
  class Ec2::Reified::Node
    class Image
      def self.validate_and_create_object(image_id, reified_node)
        if ami_hash = reified_node.aws_conn.image_get?(image_id)
          new(image_id, ami_hash)
        else
          fail ErrorUsage, "The ami '#{image_id}' is invalid"
        end
      end

      attr_reader :id
      def initialize(image_id, ami_obj)
        @id = image_id
        @ami      = ami_obj
      end
      private :initialize

      def exists?
        !!@ami
      end

      def root_device_name
        value(:root_device_name)
      end

      def block_device_mapping?(root_device_override_attrs = {})
        if default_block_device_mapping = value(:block_device_mapping)
          BlockDeviceMapping.ret(default_block_device_mapping, root_device_override_attrs)
        end
      end

      private

      def value(attr)
        (@ami || {})[attr]
      end

      module BlockDeviceMapping
        def self.ret(default_block_device_mapping, root_device_override_attrs = {})
          block_device_mapping = convert_and_prune_keys(default_block_device_mapping)
          update_root_device_with_overrides(block_device_mapping, root_device_override_attrs)
        end

        private

        def self.update_root_device_with_overrides(block_device_mapping, root_device_override_attrs = {})
          ret = block_device_mapping
          overrides = root_device_override_attrs.reject do |k, _v|
            unless TargetKeys.include?(k)
              Log.error("Bad key '#{k}' in root_device_override_attrs")
              true
            end
          end
          unless overrides.empty?
            size = block_device_mapping.size
            # TODO: assuming route device is first element in array block_device_mapping; need to further validate
            [block_device_mapping.first.merge(root_device_override_attrs)] + block_device_mapping[1..size]
          else
            ret
          end
        end

        def self.convert_and_prune_keys(block_device_mapping)
          block_device_mapping.map do |one_mapping|
            KeyMapping.inject({}) do |h, (k1, k2)|
              one_mapping.key?(k1) ? h.merge(k2 => one_mapping[k1]) : h
            end
          end
        end
        KeyMapping = {
          'deviceName'          => 'DeviceName',
          'snapshotId'          => 'Ebs.SnapshotId',
          'volumeSize'          => 'Ebs.VolumeSize',
          'deleteOnTermination' => 'Ebs.DeleteOnTermination',
          'virtualName'         => 'VirtualName'
        }
        TargetKeys = KeyMapping.values
      end
    end
  end
end; end
