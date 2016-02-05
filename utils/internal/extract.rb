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
# TODO: Marked for removal [Haris]
module XYZ
  class Extract
    class << self
      def into_directory(compressed_file, target_dir, opts = {})
        fail Error.new("directory (#{target_dir}) does not exist") unless File.directory?(target_dir)
        # TODO: rmove or make work with windows raise Error.new("directory (#{target_dir}) is not fully qualified") unless fully_qualified_dir_path?(target_dir)
        load_and_return_adapter_class(compressed_file).into_directory(compressed_file, target_dir, opts)
      end

      private

      def empty_dir?(path)
        return nil unless File.directory?(path)
        Dir.foreach(path) { |f| return nil  unless f =~ /^\./ }
        true
      end
      # TODO: rmove or make work with windows
      def fully_qualified_dir_path?(path)
        path[0, 1] == '/'
      end

      def load_and_return_adapter_class(compressed_file)
        adapter_name =
          if compressed_file =~ /\.tar\.gz$/ then :tar_gz
          else
            fail Error.new("not treating compressed file (#{compressed_file})")
          end
        CachedAdapterClasses[adapter_name] ||= DynamicLoader.load_and_return_adapter_class('extract', adapter_name)
      end
      CachedAdapterClasses = {}

      def ret_relative_path(entry_name, opts)
        return entry_name unless strip_count = opts[:strip_prefix_count]
        split = entry_name.split('/')
        split[strip_count..split.size - strip_count].join('/')
      end

      def skip(relative_path, opts)
        # strip out the empty top directory
        return true if relative_path.empty?
        # allows strip out .git directories
        return true if relative_path.split('/').first == '.git'
        return nil unless filter = opts[:filter]
        # TODO: starting very simple
        if filter.size == 1 && filter.keys.first == :modules
          not filter[:modules].include?(relative_path.split('/').first)
        else
          fail Error.new("Not treating filter: #{filter.inspect}")
        end
      end
    end
  end
end