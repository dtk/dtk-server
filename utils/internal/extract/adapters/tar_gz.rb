require 'zlib'
require 'archive/tar/minitar'
require 'fileutils'
module XYZ
  class ExtractTarGz < Extract
    def self.into_directory(compressed_file,target_dir,opts={})
      Zlib::GzipReader.open(compressed_file) do |gzip|
        Archive::Tar::Minitar::Reader.open(gzip).each do |entry|
          relative_path = ret_relative_path(entry.name,opts)
          next if skip(relative_path,opts)
          full_path = "#{target_dir}/#{relative_path}"
          if entry.directory?()
            # TODO: if can be sure that subdirectories allwos appear first and with pruning than dont need _p version
            FileUtils.mkdir_p(full_path)
          elsif entry.file?()
            begin
             copy_file(entry,full_path)
             ensure
              entry.close
            end
          end
        end
      end
    end

    private

    def self.copy_file(entry,out_file_path)
      # TODO: for larger files need more increemntal way of doing this
      File.open(out_file_path,'w') do |out_file|
        out_file << entry.read
        out_file.chmod(entry.mode)
      end
    end
  end
end
