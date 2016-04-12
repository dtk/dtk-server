#!/usr/bin/env ruby
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
require 'yaml'
require File.expand_path('require_first_minimal', File.dirname(__FILE__))
dtk_require('library_nodes')

output_file = ARGV[0]
module DTK
  module Utility
    module CreateNodeTemplateModule
      def self.create(output_file)
        node_info = LibraryNodes.ret_nodes_info_content_from_config_file
        images_attribute_value = images_attribute_value(node_info)
        yaml_content = YAML.dump(hash_content(images_attribute_value))
        if output_file
          File.open(output_file, 'w') { |f| f << yaml_content }
        else
          STDOUT << yaml_content
        end
      end
      
      
      private
      
      def self.images_attribute_value(node_info)
        # top level is region, followed by logical name of image
        unordered_ret = {}
        node_info.each_pair do |ami, info|
          region_info = unordered_ret[info['region']] ||= {}
          logical_name = info['type']
          sizes_hash = info['sizes'].sort.inject({}) { |h, ec2_size| h.merge(size_logical_name(ec2_size) => ec2_size) }
          region_info[logical_name] = {
            'ami' => ami,
            'os_type' => info['os_type'],
            'sizes' => sizes_hash
          }
        end

        # sort regions and logical names
        unordered_ret.keys.sort.inject({}) do |h, region_name|
          unordered_region = unordered_ret[region_name]
          sorted_region_info = unordered_region.keys.sort.inject({}) { |h2, logical_name| h2.merge(logical_name => unordered_region[logical_name]) }
          h.merge(region_name => sorted_region_info)
        end
      end

      def self.size_logical_name(ec2_size)
        ec2_size.split('.').last
      end

      ComponentModuleName = 'image_aws'
      DslVersion = '1.0.0' 
      ImagesAttributeName = 'images'

      def self.hash_content(images_attribute_value)
        {
          'module' => ComponentModuleName,
          'dsl_version' => DslVersion,
          'components' => {
            ComponentModuleName => {
              'attributes' =>  {
                ImagesAttributeName => {
                  'description'  =>  'Mapping of logical image names to amis',
                  'type'  =>  'hash',
                  'hidden' => true,
                  'default' => images_attribute_value
                }
              }
            }
          }
        }
      end
    end
  end
end

DTK::Utility::CreateNodeTemplateModule.create(output_file)
