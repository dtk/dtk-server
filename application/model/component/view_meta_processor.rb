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
module XYZ
  module ComponentViewMetaProcessor
    def create_view_meta_from_layout_def(view_type, layout_def)
      case view_type
        when :edit then ViewMetaProcessorInternals.create_from_layout_def__edit(layout_def)
        else fail Error.new("not implemented for view type #{view_type}")
      end
    end

    module ViewMetaProcessorInternals
      def self.create_from_layout_def__edit(layout_def)
        ret = ActiveSupport::OrderedHash.new()
        ret[:action] = ''
        ret[:hidden_fields] = hidden_fields(:edit)
        ret[:field_groups] = field_groups(layout_def)
        ret
      end

      def self.field_groups(layout_def)
        (layout_def[:groups] || []).map do |group|
          { num_cols: 1,
            display_labels: true,
            fields: group[:fields].map { |r| { r[:name].to_sym => r } }
          }
        end
      end

      def self.hidden_fields(type)
        HiddenFields[type].map do |hf|
          { hf.keys.first => Aux.ordered_hash_subset(hf.values.first, [:required, :type, :value]) }
        end
      end
      HiddenFields = {
        list:         [
         { id: {
             required: true,
             type: 'hidden'
           } }
        ],
        edit:         [
         {
           id: {
             required: true,
             type: 'hidden'
           }
         },
         {
           model: {
             required: true,
             type: 'hidden',
             value: 'component'
           }
         },
         {
           action: {
             required: true,
             type: 'hidden',
             value: 'save_attribute'
           }
         }
        ],
        display:         [
         {
           id: {
             required: true,
             type: 'hidden'
           }
         },
         {
           obj: {
             required: true,
             type: 'hidden',
             value: 'component'
           }
         },
         {
           action: {
             required: true,
             type: 'hidden',
             value: 'edit'
           }
         }
        ]
      }
    end
  end
end