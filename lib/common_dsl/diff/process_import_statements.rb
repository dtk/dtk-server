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
    # For processing diffs that have import statements (ie, importing nested dsl files)
    class ProcessImportStatements
      # opts can have keys:
      #   :impacted_files
      def initialize(opts = {})
        @impacted_files = opts[:impacted_files]
      end
      private :initialize

      # The method modify_to_process_import_statements! modifies if needed gen_obj and parse_obj
      # so a simple 'syntactic' test can determine whether they are equal
      # TODO: DTK-2738: update logic from what is put in now: simple look into gen_obj to see if import statement and if so removing it
      #   to approach that looks in impacted files to handlke following features
      #   - checks if gen_obj has any import statements and whether any if these files have been changed (by looking at impacted_files)
      #     If any of these are changed we need to update what is stored in the database to splice this information in and to do syntatuc comparison
      #     splice this info into gen_obj
      #   - otherwise removes from gen_obj all import statements to do a comparison (this part is done)
      #   - looks for import statements in parse_obj recursively
      #   - for impacted files, rather than passing in just file path names, shoudl pass in path/content pair
      def self.modify_for_syntactic_comparison!(gen_obj, parse_obj, opts = {})
        new(opts).modify_for_syntactic_comparison!(gen_obj, parse_obj)
      end
      def modify_for_syntactic_comparison!(gen_obj, parse_obj)
        if nested_dsl_files = imported_files?(gen_obj)
          remove_imported_statements!(gen_obj)
        end
      end

      private

      # returns either file imported at top level or nil
      def imported_file_top_level?(obj)
        hash_value_under_key?(obj, :Import)
      end

      # returns either an array of import file in gen_obj or nil if none
      def imported_files?(obj)
        if obj.kind_of?(::Hash)
          if imported_file = imported_file_top_level?(obj)
            [imported_file]
          else
            imported_files__array?(obj.values)
          end
        elsif obj.kind_of?(::Array)
          imported_files__array?(obj)
        end
      end

      def imported_files__array?(array)
        ret = []
        array.each do |obj|
          if files = imported_files?(obj)
            ret += files
          end
        end
        ret.empty? ? nil : ret
      end

      def remove_imported_statements!(obj)
        if obj.kind_of?(::Hash)
          remove_imported_statements__hash!(obj)
        elsif obj.kind_of?(::Array)
          remove_imported_statements__array!(obj)
        end
      end

      def remove_imported_statements__hash!(hash_obj)
        hash_obj.each_pair do |key, nested_obj| 
          if imported_file_top_level?(nested_obj)
            if is_hidden_import_statement?(nested_obj)
              hash_obj.delete(key)
            else 
              keep_just_import_statement!(nested_obj)
            end
          else
            remove_imported_statements!(nested_obj)
          end
        end
      end

      def remove_imported_statements__array!(array_obj)
        array_obj.each_with_index do |nested_obj, i| 
          if imported_file_top_level?(nested_obj)
            if is_hidden_import_statement?(nested_obj)
              array_obj.delete_at(i)
            else 
              keep_just_import_statement!(nested_obj)
            end
          else
            remove_imported_statements!(nested_obj) 
          end 
        end
      end

      def keep_just_import_statement!(obj)
        if obj.respond_to?(:remove_all_except!)
          obj.remove_all_except!(:Import)
        end
      end

      def is_hidden_import_statement?(obj)
        hash_value_under_key?(obj, :HiddenImportStatement)
      end

      def hash_value_under_key?(obj, key)
        obj.val(key) if obj.kind_of?(::Hash) and obj.respond_to?(:val)
      end

    end
  end
end

