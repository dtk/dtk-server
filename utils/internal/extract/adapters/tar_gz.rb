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
require 'zlib'
require 'archive/tar/minitar'
require 'fileutils'
module XYZ
  class ExtractTarGz < Extract
    def self.into_directory(compressed_file, target_dir, opts = {})
      Zlib::GzipReader.open(compressed_file) do |gzip|
        Archive::Tar::Minitar::Reader.open(gzip).each do |entry|
          relative_path = ret_relative_path(entry.name, opts)
          next if skip(relative_path, opts)
          full_path = "#{target_dir}/#{relative_path}"
          if entry.directory?()
            # TODO: if can be sure that subdirectories allwos appear first and with pruning than dont need _p version
            FileUtils.mkdir_p(full_path)
          elsif entry.file?()
            begin
             copy_file(entry, full_path)
             ensure
              entry.close
            end
          end
        end
      end
    end

    private

    def self.copy_file(entry, out_file_path)
      # TODO: for larger files need more increemntal way of doing this
      File.open(out_file_path, 'w') do |out_file|
        out_file << entry.read
        out_file.chmod(entry.mode)
      end
    end
  end
end