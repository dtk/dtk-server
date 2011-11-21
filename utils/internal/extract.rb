module XYZ
  class Extract
    class << self 
      def into_directory(compressed_file,target_dir,opts={})
        load_and_return_adapter_class(compressed_file).into_directory(compressed_file,target_dir,opts)
      end
     private
      def load_and_return_adapter_class(compressed_file)
        adapter_name = 
          if compressed_file =~ /\.tar\.gz$/ then :tar_gz
          else
            raise Error.new("not treating compressed file (#{compressed_file})")
          end
        CachedAdapterClasses[adapter_name] ||= DynamicLoader.load_and_return_adapter_class("extract",adapter_name)
      end
      CachedAdapterClasses = Hash.new
    end
  end
end
