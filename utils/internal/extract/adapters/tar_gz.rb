require 'zlib'
require 'archive/tar/minitar'
module XYZ
  class ExtractTarGz < Extract
    class << self
      def into_directory(compressed_file,target_dir,opts={})
        Zlib::GzipReader.open(compressed_file) do |gzip|
          Archive::Tar::Minitar::Reader.open(gzip).each do |entry|
            relative_path = ret_relative_path(entry.name,opts)
            unless skip(relative_path,opts)
              pp [:foo,relative_path]
              #entry.read
              #entry.close
            end
          end
        end
      end
     private
    end
  end
end
