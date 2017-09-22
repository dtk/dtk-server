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
  module Attribute::PropagateChanges
    class DerivedSource
      def initialize(derived_source)
        @derived_source = derived_source
      end
      private :initialize

      def self.create?(attribute)
        if derived_source = attribute.get_field?(:derived_source)
          new(derived_source)
        end
      end

      # returns [pruned_attributes, pruned_ndx_new_values]
      def self.prune_propagated(existing_attributes, ndx_new_values)
        pruned_attributes  = existing_attributes.reject do |attribute| 
          if derived_source_object = create?(attribute)
            derived_source_object.is_propagated? 
          end
        end
        pruned_ids            = pruned_attributes.map(&:id)
        pruned_ndx_new_values = ndx_new_values.inject({}) { |h, (id, v)| pruned_ids.include?(id) ? h.merge(id => v) : h }  
        
        [pruned_attributes, pruned_ndx_new_values]
      end

      def self.update_from_propagated(attr_mh, update_deltas)
        return if update_deltas.empty?
        attributes = update_deltas.map { |attr_hash| attr_mh.createIDH(id: attr_hash[:id]).create_object.merge(attr_hash) }
        ndx_existing_derived_source = ndx_existing_derived_source(attributes)

        update_rows = update_deltas.map do |update_delta|
          id = update_delta[:id]
          {
            id: id,
            derived_source: derived_source_from_propagated(update_delta, ndx_existing_derived_source[id])
          }
        end
        Model.update_from_rows(attributes.first.model_handle, update_rows) 
      end

      def self.default(default_value)
        default_hash_form(default_value)
      end
      
      def is_propagated?
        ! self.propagated_info?.nil?
      end

      # TODO: DTK-2601; use this when implement update to dervid source when component is deleted
      def hash_after_deleted_source(source_id)
        updated_source_ids = self.source_ids - [source_id.to_s]
        if updated_source_ids.empty?
          # remove the Key::PROPAGATED key
          self.derived_source.inject({}) { | h, (k, v) | k == Key::PROPAGATED ? h : h.merge(k => v) }
        else
          self.class.deep_merge(self.derived_source, self.class_propagated_hash_form(*updated_source_ids))
        end
      end

      protected
      
      attr_reader :derived_source

      def propagated_info?
        self.derived_source[Key::PROPAGATED]
      end

      def source_ids
        (self.propagated_info? || {})[Key::SOURCE_IDS] || []
      end

      private

      def self.default_hash_form(default_value)
        { Key::DEFAULT => { Key::DEFAULT_VALUE => default_value } }
      end
      
      def self.propagated_hash_form(*source_ids)
        source_ids.empty? ? {} : { Key::PROPAGATED => { Key::SOURCE_IDS => source_ids.map(&:to_s) } } 
      end
      
      def self.ndx_existing_derived_source(attributes)
        sp_hash = {
          cols: [:id, :derived_source],
          filter: [:oneof, :id, attributes.map(&:id)]
        }
        Model.get_objs(attributes.first.model_handle, sp_hash).inject({}) { |h, attribute| h.merge(attribute.id => attribute[:derived_source]) }
      end

      def self.derived_source_from_propagated(update_delta, existing_derived_source)
        if source_id = update_delta[:source_output_id]
          deep_merge(existing_derived_source || {}, propagated_hash_form(source_id))
        else
          Log.error("unexpected that update_delta[:source_output_id] is nil")
          existing_derived_source
        end
      end

      def self.deep_merge(existing_hash, new_hash)
        new_hash.inject(existing_hash) do |h, (k, v)|
          existing_value = existing_hash[k]
          if existing_value.nil?
            h.merge(k => v)
          else
            if existing_value.kind_of?(::Hash) and v.kind_of?(::Hash)
              h.merge(k => deep_merge(existing_value, v))
            else
              h.merge(k => v)
            end
          end 
        end
      end

      module Key
        DEFAULT        = 'default'
        PROPAGATED     = 'propagated'
        SOURCE_IDS     = 'source_idS'
        DEFAULT_VALUE  = 'default_value'
      end

    end
  end
end
