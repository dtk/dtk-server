module DTK
  class ServiceAddOn < Model
    def self.import(library_idh,meta_file,hash_content)
      type = (meta_file =~ MetaRegExp;$1)
      pp [:bedug, meta_file,type,hash_content]
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
