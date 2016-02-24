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
module DTK; class NodeBindings::NodeTarget
  class Image
    module LegalFields
      def self.create_if_matches?(input)
        # TODO: if fail here on parsing pass or raise specfic error; rather than current behavior to pass nil
        #   Errors detected are: 
        #   - missing required fields
        #   - illegal value
        if Aux.has_only_these_keys?(input, AllDSLFields) && !RequiredDSLFields.find { |k| !input.key?(k) }
          internal_form_hash = input.inject({}) { |h, (k, v)| h.merge(InputFormToInternal[k] => v) }
          map_to_canonical_form!(internal_form_hash)
          if has_legal_values?(internal_form_hash)
            fill_in_defaults!(internal_form_hash)
            Image.new(internal_form_hash)
          end
        end
      end

      def self.external_ref?(image_type)      
        { type: image_type }
      end

      private

      def self.map_to_canonical_form!(internal_form_hash)
        CanonicalForm.each_pair do |key, mapping|
          if internal_form_hash.has_key?(key)
            value = internal_form_hash[key]
            if  mapping.has_key?(value)
              internal_form_hash[key] = mapping[value]
            end
          end
        end
      end

      def self.has_legal_values?(internal_form_hash)
        first_violation = internal_form_hash.find do |key, value| 
          # when reach here the values wil have been mapped to canonical values
          if legal_values = (Fields[key] || {})[:canonical_values]
            unless legal_values.include?(value)
              Log.info("Illegal value for node target key #{key}=#{value.inspect}; legal vaules are #{legal_values.inspect}")
              true
            end
          end
        end
        first_violation.nil? # true if no violations
      end

      def self.fill_in_defaults!(internal_form_hash)
        DefaultValues.each_pair {|key, value| internal_form_hash[key] ||= value }
      end
      
    Fields = {
        image: {
          key: 'image',
          required: true
      },
        size: {
          key: 'size'
        },
        image_type: {
          key: 'type',
          default: 'ec2_image',
          canonical_values: ['ec2_image', 'bosh_stemcell'],
          aliases: {'ec2' => 'ec2_image', 'bosh' => 'bosh_stemcell' }
        }
    }
      InputFormToInternal = Fields.inject({}) { |h, (k, v)| h.merge(v[:key] => k) }
      AllDSLFields        = Fields.values.map { |f| f[:key] }
      RequiredDSLFields   = Fields.values.select { |f| f[:required] }.map { |f| f[:key] }
      DefaultValues       = Fields.select { |k, v| v[:default] }.inject({}) { |h, (k, v)| h.merge(k => v[:default]) }
      CanonicalForm       = Fields.select { |k, v| v[:aliases] }.inject({}) { |h, (k, v)| h.merge(k => v[:aliases]) }
    end
  end
end; end
