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
      end

      def self.hash_content(images_attribute_value)
        ComponentModuleHeader 
      end
        
      ComponentModuleName = 'image_aws'
      DslVersion = '1.0.0' 
      ImagesAttributeName = 'images'
      ComponentModuleHeader = {
        'module' => ComponentModuleName,
        'dsl_version' => DslVersion,
        'components' => {
          ComponentModuleName => {
            'attributes' =>  {
              ImagesAttributeName => {
                'description'  =>  'Mapping of logical image names to amis',
                'type'  =>  'hash'
              }
            }
          }
        }
      }
      

    end
  end
end
DTK::Utility::CreateNodeTemplateModule.create(output_file)
