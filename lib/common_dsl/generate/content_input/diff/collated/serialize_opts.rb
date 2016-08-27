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
module DTK; module CommonDSL::Generate
  class ContentInput::Diff
    class SerializeOpts < ::Hash
      REQUIRED_KEYS = [:dsl_version]
      OPTIONAL_KEYS = [:label]
      # opts can have keys
      #   :dsl_version (required)
      #   :label
      def initialize(opts = {})
        super()
        REQUIRED_KEYS.each do |key|
          val  = opts[key]
          fail Error, "Unexpected that opts[#{key}] is nil" if val.nil?
          merge!(key => opts[key])
        end
        OPTIONAL_KEYS.each do |key|
          merge!(key => opts[key]) unless opts[key].nil?
        end
      end

      LABEL_ELEMENT_DELIM = '/'
      def with_nested_label(parent_type, parent_key)
        ret = copy
        base_label = ret[:label]
        if parent_type and parent_key
          label_element = SerializedHash.label?(type: parent_type, key: parent_key)
          nested_label = base_label ? "#{base_label}#{LABEL_ELEMENT_DELIM}#{label_element}" : label_element
          ret.merge!(:label => nested_label) if nested_label
        end
        ret
      end

      private

      def copy
        self.class.new(self)
      end

    end
  end
end; end
