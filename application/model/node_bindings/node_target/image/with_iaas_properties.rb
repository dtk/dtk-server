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
  class NodeBindings::NodeTarget::Image
    class WithIAASProperties < self
      IAASPropertiesDSLField = 'iaas_properties'
      IAASPropertiesObjectKey = :iaas_properties      

      def initialize(iaas_properties)
        super({})
        @iaas_properties = iaas_properties
      end
      private :initialize

      def self.create_if_matches?(input)
        # first clause for input second is when it sobject alreddy
        if Aux.has_just_these_keys?(input, [IAASPropertiesDSLField])
          new(input[IAASPropertiesDSLField])
        elsif iaas_properties = input[IAASPropertiesObjectKey]
          new(iaas_properties)
        end
      end
      
      def hash_form
        super.merge(iaas_properties: @iaas_properties)
      end
    end
  end
end

