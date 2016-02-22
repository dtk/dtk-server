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
  class NodeBindings; class NodeTarget::Image
    # Class for node bindings with an explicity iaas_properties section                        
    class WithIAASProperties < self
      module DSLField
        IAASProperties = 'iaas_properties'
        ImageType = 'image_type'
      end

      attr_reader :image_type

      def initialize(hash)
        super({})
        @iaas_properties = hash[:iaas_properties]
        @image_type = hash[:image_type]
      end
      private :initialize
      def hash_form
        super.merge(iaas_properties: @iaas_properties, image_type: @image_type)
      end

      def self.create_if_matches?(input)
        if input.kind_of?(ContentField) #content read from db to reify; must go before Hash test since this is a hash
          new(input)
        elsif input.kind_of?(Hash) # called if parsing from DSL
          if Aux.has_just_these_keys?(input, [DSLField::IAASProperties])
            iaas_properties = input[DSLField::IAASProperties]
            image_type = iaas_properties[DSLField::ImageType]
            new(iaas_properties: iaas_properties, image_type: image_type)
          end
        else
          fail Error.new("Unexpected class for input: #{input.class}")
        end
      end
      
    end
  end
end; end

