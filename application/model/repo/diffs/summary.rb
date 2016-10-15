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
module DTK; class Repo
  class Diffs
    class Summary < SimpleHashObject

      DiffNames  = [:renamed, :added, :deleted, :modified]
      DiffTypes  = DiffNames.map { |n| "files_#{n}".to_sym }
      DiffIgnore = [:are_there_changes]

      def initialize(diffs_hash = nil)
        super()
        (diffs_hash || {}).each do |t, v|
          next if DiffIgnore.include?(t.to_sym)
          t = t.to_sym
          if DiffTypes.include?(t)
            self[t] = v
          else
            Log.error("unexpected summary diff type (#{t})")
          end
        end
      end

      def no_diffs?
        keys.empty?
      end

      def impacted_files
        ret = []
        DiffTypes.each do |diff_type|
          if files = self[diff_type]
            ret += files.map {|file| file[:path]}
          end
        end
        ret
      end

      def reverse
        reverse_hash = {
          files_modified: self[:files_modified], 
          files_renamed: self[:files_renamed], 
          files_added: self[:files_deleted],
          files_deleted: self[:files_added]
        }
        self.class.new(reverse_hash)
      end

      def no_added_or_deleted_files?
        not (self[:files_renamed] || self[:files_added] || self[:files_deleted])
      end

      # opts can have
      # :type which can be terms :module_dsl,:module_refs
      #    indicated what type of meta file to look for
      def meta_file_changed?(opts = {})
        contains_a_dsl_filename?(self[:files_modified], opts) ||
          contains_a_dsl_filename?(self[:files_added], opts)
      end

      def file_changed?(path)
        self[:files_modified] && !!self[:files_modified].find { |r| path(r) == path }
      end

      # note: in paths_to_add and paths_to_delete rename appears both since rename can be accomplsihed by a add + a delete
      def paths_to_add
        (self[:files_added] || []).map { |r| path(r) } + (self[:files_renamed] || []).map { |r| r[:new_path] }
      end

      def paths_to_delete
        (self[:files_deleted] || []).map { |r| path(r) } + (self[:files_renamed] || []).map { |r| r[:old_path] }
      end

      private

      def path(r)
        r['path'] || r[:path]
      end

      def contains_a_dsl_filename?(files_info, opts = {})
        return unless files_info
        types = (opts[:type] ? [opts[:type]] : [:module_dsl, :module_refs])
        !!files_info.find do |r|
          (types.include?(:module_dsl) && ModuleDSL.isa_dsl_filename?(path(r))) ||
            (types.include?(:module_refs) && ModuleRefs.isa_dsl_filename?(path(r)))
        end
      end

    end
  end
end; end
