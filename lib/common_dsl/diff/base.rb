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
  class CommonDSL::Diff
    class Base < self
      require_relative('base/collate')

      include Collate::Mixin

      attr_reader :current_val, :new_val, :id_handle, :qualified_key
      # opts can have keys
      #   :qualified_key (required)
      #   :id_handle (required)
      #   :service_instance
      #   :type
      def initialize(current_val, new_val, opts = {})
        fail Error, "Unexpected that opts[:qualified_key] is nil" unless opts[:qualified_key]
        fail Error, "Unexpected that opts[:id_handle] is nil" unless opts[:id_handle]

        super(qualified_key: opts[:qualified_key], type: opts[:type], service_instance: opts[:service_instance])
        @id_handle   = opts[:id_handle]
        @current_val = current_val
        @new_val     = new_val
      end
      private :initialize

      # opts can have keys
      #   :qualified_key
      #   :id_handle
      #   :service_instance
      #   :impacted_files
      def self.diff?(current_val, new_val, opts = {})
        new_opts = { qualified_key: opts[:qualified_key], id_handle: opts[:id_handle], service_instance: opts[:service_instance] }
        new(current_val, new_val, new_opts) if has_diff?(current_val, new_val, impacted_files: opts[:impacted_files])
      end

      def self.aggregate?(diff_sets, opts = {}, &body)
        set_class.aggregate?(diff_sets, with_diff_class(opts), &body)
      end
      
      def self.between_hashes(gen_hash, parse_hash, qualified_key, opts = {})
        set_class.between_hashes(gen_hash, parse_hash, qualified_key, with_diff_class(opts))
      end

      def self.between_arrays(gen_array, parse_array, qualified_key, opts = {})
        set_class.between_arrays(gen_array, parse_array, qualified_key, with_diff_class(opts))
      end

      def self.array_of_diffs_on_matching_keys(gen_hash, parse_hash, qualified_key)
        set_class.array_of_diffs_on_matching_keys(gen_hash, parse_hash, qualified_key)
      end

      private

      def self.set_class
        CommonDSL::Diff::Set
      end

      def self.with_diff_class(opts)
        opts.merge(diff_class: self)
      end

      def create_modify_element
        self.class::Modify.new(self)
      end

      # opts can have keys:
      #   :impacted_files
      #   :donot_process_import_statements
      def self.has_diff?(current_val, new_val, opts = {})
        if current_val.respond_to?(:to_s) and new_val.respond_to?(:to_s) and current_val.to_s == new_val.to_s
          false
        elsif current_val.kind_of?(::Hash) and new_val.kind_of?(::Hash)
          has_diff__hash?(current_val, new_val, opts)
        elsif current_val.kind_of?(::Array) and new_val.kind_of?(::Array)
          has_diff__array?(current_val, new_val, opts)
        else
          current_val != new_val
        end
      end

      # opts can have keys:
      #   :impacted_files
      #   :donot_process_import_statements
      def self.has_diff__array?(current_val_array, new_val_array, opts = {})
        ret = true
        if current_val_array.size == new_val_array.size
          current_val_array.each_with_index do |current_val, i|
            return true if has_diff?(current_val, new_val_array[i], opts)
          end
          ret = false
        end
        ret
      end

      # opts can have keys:
      #   :impacted_files
      #   :donot_process_import_statements
      def self.has_diff__hash?(current_val_hash, new_val_hash, opts = {})
        ret = true
        unless opts[:donot_process_import_statements]
          ProcessImportStatements.modify_for_syntactic_comparison!(current_val_hash, new_val_hash, impacted_files: opts[:impacted_files])
          opts = opts.merge(donot_process_import_statements: true)
        end

        if current_val_hash.keys.sort == new_val_hash.keys.sort
          current_val_hash.keys.each do |key|
            return true if has_diff?(current_val_hash[key], new_val_hash[key], opts)
          end
          ret = false
        end
        ret
      end
      
    end
  end
end
