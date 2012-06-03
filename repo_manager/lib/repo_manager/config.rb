module R8RepoManager
  class Config < Hash
    include Singleton
    #include ParseFile
    def self.[](k)
      Config.instance[k]
    end
   private
    def initialize()
      set_defaults()
      #load_config_file()
      validate()
    end
    def set_defaults()
      self[:admin_repo_dir] = '/home/gitolite-admin/gitolite-admin.git'
    end
    #ConfigFile = "/etc/r8client/client.conf"
    def load_config_file()
      parse_key_value_file(ConfigFile).each{|k,v|self[k]=v}
    end
    RequiredKeys = [:server_host]
    def validate
      #TODO: need to check for legal values
      missing_keys = RequiredKeys - keys
      raise Error.new("Missing config keys (#{missing_keys.join(",")})") unless missing_keys.empty?
    end
  end
end
