require 'zlib'
require 'archive/tar/minitar'
module XYZ
  class ExtractTarGz < Extract
    class << self
      def into_directory(compressed_file,target_dir,opts={})
        Zlib::GzipReader.open(compressed_file) do |gzip|
          Archive::Tar::Minitar::Reader.open(gzip).each do |entry|
            qualified_filename = ret_qualified_filename(entry.name,opts)
            unless skip(qualified_filename,opts)
              pp [:foo,qualified_filename]
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
