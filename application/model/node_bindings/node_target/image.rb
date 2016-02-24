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
module DTK; class NodeBindings
  class NodeTarget
    class Image < self
      r8_nested_require('image', 'legal_fields')
      r8_nested_require('image', 'with_iaas_properties')

      NodeTargetType = :image

      attr_reader :image
      def initialize(hash)
        super(NodeTargetType)
        @image_type = hash[:image_type]
        @image      = hash[:image]
        @size       = hash[:size]
      end

      # returns a TargetSpecificObject
      def find_target_specific_info(target)
        ret = TargetSpecificInfo.new(self)
        if @image
          unless image_id = NodeImage.find_iaas_match(target, @image)
            fail ErrorUsage.new("The image (#{@image}) in the node binding does not exist in the target (#{target.get_field?(:display_name)})")
          end
          ret.image_id = image_id
        end
        if @size
          unless iaas_size = NodeImageAttribute::Size.find_iaas_match(target, @size)
            fail ErrorUsage.new("The size (#{@size}) in the node binding is not valid in the target (#{target.get_field?(:display_name)})")
          end
          ret.size = iaas_size
        end
        ret
      end

      def hash_form
        { type: type().to_s, image: @image, size: @size }
      end

      def match_or_create_node?(_target)
        :create
      end

      def self.parse_and_reify(parse_input, _opts = {})
        if parse_input.type?(ContentField)
          input = parse_input.input
          if input[:type].to_sym == NodeTargetType
            WithIAASProperties.create_if_matches?(input) || new(input)
          end
        elsif parse_input.type?(Hash)
          input = parse_input.input
          LegalFields.create_if_matches?(input) || WithIAASProperties.create_if_matches?(input)
        end
      end
    end
  end
end; end
