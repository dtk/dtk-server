module DTK
  class ServiceAddOn < Model
    def self.import(service_module,ports,meta_file,hash_content)
      type = (meta_file =~ MetaRegExp;$1)
      pp [:debug,service_module, meta_file,type,hash_content]
    end
    def self.meta_filename_path_info()
      {
        :regexp => MetaRegExp,
        :path_depth => 4
      }
    end
    MetaRegExp = Regexp.new("add-ons/([^/]+)\.json$")
  end
end
