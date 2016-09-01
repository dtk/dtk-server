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
module DTK; class Attribute
  class LegalValue
    # opts can have keys:
    #   :only_special_processing
    def self.raise_error_if_invalid(existing_attrs, ndx_new_vals, opts = {})
      errors = ErrorsUsage.new
      existing_attrs.each do |attr|
        attr.update_object!(:node_node_id, :component_component_id, :semantic_data_type) # proactive in fields needed
        new_val = ndx_new_vals[attr[:id]]
        special_processing, error = SpecialProcessing::ValueCheck.error_special_processing?(attr, new_val)
        if special_processing
          errors << error if error
        else
          unless opts[:only_special_processing]
            if semantic_data_type = attr[:semantic_data_type]
              errors << Error.new(attr, new_val) unless SemanticDatatype.is_valid?(semantic_data_type, new_val)
            end
          end
        end
        
        fail errors unless errors.empty?
      end
    end

    class Error < ErrorUsage
      def initialize(attr, new_val, info = {})
        super(error_msg(attr, new_val, info))
      end

      private

      def error_msg(attr, new_val, info)
        attr_name = attr[:display_name]
        ret = "Attribute '#{attr}' has illegal value #{new_val.inspect}"
        if legal_vals = info[:legal_values]
          ident = ' ' * 2;
          sep = '--------------'
          ret << "; legal values are: \n#{sep}\n#{ident}#{legal_vals.join("\n#{ident}")}"
          ret << "\n#{sep}\n"
        end
        ret
      end
    end
  end
end; end
