require 'zlib'
require 'archive/tar/minitar'
module XYZ
  class ExtractTarGz < Extract
    class << self
      def into_directory(compressed_file,target_dir,opts)
        pp "****************************"
      end
    end
  end
end
