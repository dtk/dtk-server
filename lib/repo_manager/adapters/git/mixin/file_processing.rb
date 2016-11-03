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
  class RepoManager::Git
    module Mixin
      # Instance mixin for adding, deleting, listing, creating and moving files
      module FileProcessing
        
        #### Adding files
        # returns a Boolean: true if any change made
        # opts can have keys:
        #  :commit_msg
        #  :no_commit
        def add_files(file_path__content_array, opts = {})
          ret = false
          added_file_paths = []
          file_path__content_array.each do |el|
            path = el[:path]
            if add_file({ path: path }, el[:content], nil, no_commit: true)
              added_file_paths << path
              ret = true
            end
          end
          if ret and ! opts[:no_commit]
            commit_msg ||= "Adding files: #{added_file_paths.join(', ')}"
            checkout(@branch) { commit(commit_msg) }
          end
          ret
        end
        
        # returns a Boolean: true if any change made
        # opts can have keys:
        #   :no_commit - Boolean
        def add_file(file_asset, content, commit_msg = nil, opts = {})
          ret = false
           path = file_asset[:path]
          commit_msg ||= "Adding file '#{path}'"
          content ||= ''
          checkout(@branch) do
            recursive_create_dir?(path)
             File.open(path, 'w') { |f| f << content }
            git_command__add(path)
            # diff(nil) looks at diffs with respect to the working dir
            unless diff(nil).ret_summary.no_diffs?
              commit(commit_msg) unless opts[:no_commit]
              ret = true
            end
          end
          ret
        end

        #### Deleting files and directories

        # opts for four methods below can have keys:
        #  :commit_msg
        #  :no_commit
        #  :push_changes
        def delete_file?(file_path, opts = {})
          delete_tree?(:file, file_path, opts)
        end
        def delete_directory?(dir, opts = {})
          delete_tree?(:directory, dir, opts)
        end
        def delete_file(file_path, opts = {})
          delete_tree(:file, file_path, opts)
        end
        def delete_directory(dir, opts = {})
          delete_tree(:directory, dir, opts)
        end
        def delete_tree?(type, tree_path, opts = {})
          ret = nil
          checkout(@branch) do
            ret = File.exist?(full_path(tree_path))
            delete_tree(type, tree_path, opts.merge(no_checkout: true)) if ret
          end
          ret
        end

        # opts can have keys:
        #  :commit_msg
        #  :no_commit
        #  :push_changes
        #  :no_checkout
        def delete_tree(type, path, opts = {})
          if opts[:no_checkout]
            delete_tree__body(type, path, opts)
          else
            checkout(@branch) do
              delete_tree__body(type, path, opts)
            end
          end
        end

        #### Querying and listing files and directories 
        def file_exists?(file_path)
          checkout(@branch) do
            File.exist?(file_path)
          end
        end

        def ls_r(depth = nil, opts = {})
          checkout(@branch) do
            if depth.nil? || (depth.is_a?(String) && depth == '*')
              all_paths = Dir['**/*']
            else
              pattern = '*'
              all_paths = []
              depth.times do
                all_paths += Dir[pattern]
                pattern = "#{pattern}/*"
              end
            end
            if opts[:file_only]
              all_paths.select { |p| File.file?(p) }
            elsif opts[:directory_only]
              all_paths.select { |p| File.directory?(p) }
            else
              all_paths
            end
          end
        end

        #### Getting file content
        def get_file_content(file_asset, opts = {})
          checkout(@branch) do
            if opts[:no_error_if_not_found]
              unless File.exist?(file_asset[:path])
                return nil
              end
            end
            File.open(file_asset[:path]) { |f| f.read }
          end
        end

        #### Updating file content
        def update_file_content(file_asset, content)
          checkout(@branch) do
            File.open(file_asset[:path], 'w') { |f| f << content }
            # TODO: commiting because it looks like file change visible in other branches until commit
            message = "Updating #{file_asset[:path]} in #{@branch}"
            git_command__add(file_asset[:path])
            commit(message)
          end
        end
        DiffAttributes = [:new_file, :renamed_file, :deleted_file, :a_path, :b_path, :diff]
        def diff(other_branch)
          grit_diffs = @grit_repo.diff(@branch, other_branch)
          array_diff_hashes = grit_diffs.map do |diff|
            DiffAttributes.inject({}) do |h, a|
              val = diff.send(a)
              val ? h.merge(a => val) : h
            end
          end
          a_sha = branch_sha(@branch)
          b_sha = branch_sha(other_branch)
          Repo::Diffs.new(array_diff_hashes, a_sha, b_sha)
        end
        


        #### Moving files
        def move_content(source, destination, files, folders, branch = nil)
          branch ||= @branch
          checkout(branch) do
            git_command__mv(source, destination, files, folders)
          end
        end

        def move_file(source_name, destination_name, branch = nil)
          branch ||= @branch
          checkout(branch) do
            git_command__mv_file(source_name, destination_name)
          end
        end

        private

        # opts can have keys:
        #  :commit_msg
        #  :no_commit
        #  :push_changes
        def delete_tree__body(type, path, opts = {})
          message = opts[:commit_msg] || "Deleting #{path} in #{@branch}"
          case type
          when :file then git_command__rm(path)
          when :directory then git_command__rm_r(path)
          else fail Error.new("Unexpected type (#{type})")
          end
          commit(message) unless opts[:no_commit]
          if opts[:push_changes]
            push_changes
          end
        end
        
      end
    end
  end
end

